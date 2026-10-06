-- =============================================================
-- Campus Facility Booking System — Database Schema
-- =============================================================

-- Roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL CHECK (role_name IN ('ADMIN', 'FACULTY'))
);

-- Users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Room Types
CREATE TABLE IF NOT EXISTS room_types (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL
);

-- Rooms
CREATE TABLE IF NOT EXISTS rooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    room_type_id INTEGER REFERENCES room_types(id) ON DELETE RESTRICT,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    is_active BOOLEAN DEFAULT TRUE
);

-- Time Slots
CREATE TABLE IF NOT EXISTS time_slots (
    id SERIAL PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    UNIQUE(start_time, end_time),
    CHECK (start_time < end_time)
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    room_id INTEGER REFERENCES rooms(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'CONFIRMED' CHECK (status IN ('CONFIRMED', 'CANCELLED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Booking Slots (junction)
CREATE TABLE IF NOT EXISTS booking_slots (
    booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
    slot_id INTEGER REFERENCES time_slots(id) ON DELETE CASCADE,
    PRIMARY KEY (booking_id, slot_id)
);

-- =============================================================
-- Trigger: Prevent Double Booking
-- =============================================================

CREATE OR REPLACE FUNCTION check_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    conflict_count INTEGER;
    v_room_id INTEGER;
    v_date DATE;
BEGIN
    SELECT room_id, booking_date INTO v_room_id, v_date
    FROM bookings
    WHERE id = NEW.booking_id;

    SELECT COUNT(*)
    INTO conflict_count
    FROM bookings b
    JOIN booking_slots bs ON b.id = bs.booking_id
    WHERE b.room_id = v_room_id
      AND b.booking_date = v_date
      AND bs.slot_id = NEW.slot_id
      AND b.status = 'CONFIRMED'
      AND b.id != NEW.booking_id;

    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Double Booking Detected: Room % on % for slot % is already booked.', v_room_id, v_date, NEW.slot_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_double_booking ON booking_slots;

CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT ON booking_slots
FOR EACH ROW
EXECUTE FUNCTION check_double_booking();

-- =============================================================
-- Stored Procedure: Create Booking (Atomic)
-- =============================================================

CREATE OR REPLACE PROCEDURE sp_create_booking(
    p_user_id INTEGER,
    p_room_id INTEGER,
    p_booking_date DATE,
    p_slot_ids INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_booking_id INTEGER;
    v_slot_id INTEGER;
BEGIN
    INSERT INTO bookings (user_id, room_id, booking_date)
    VALUES (p_user_id, p_room_id, p_booking_date)
    RETURNING id INTO v_booking_id;

    FOREACH v_slot_id IN ARRAY p_slot_ids
    LOOP
        INSERT INTO booking_slots (booking_id, slot_id)
        VALUES (v_booking_id, v_slot_id);
    END LOOP;
END;
$$;

-- =============================================================
-- Stored Procedure: Cancel Booking
-- =============================================================

CREATE OR REPLACE PROCEDURE sp_cancel_booking(
    p_booking_id INT,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bookings
    SET status = 'CANCELLED'
    WHERE id = p_booking_id
      AND user_id = p_user_id
      AND status = 'CONFIRMED';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot cancel booking';
    END IF;
END;
$$;

-- =============================================================
-- Stored Procedure: Admin Cancel Booking (Any User)
-- =============================================================

CREATE OR REPLACE PROCEDURE sp_admin_cancel_booking(
    p_booking_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bookings
    SET status = 'CANCELLED'
    WHERE id = p_booking_id
      AND status = 'CONFIRMED';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot cancel booking or booking already cancelled';
    END IF;
END;
$$;
-- =============================================================
-- Function using Cursor: Get Room Utilization Summary
-- =============================================================

CREATE OR REPLACE FUNCTION fn_get_room_utilization()
RETURNS TABLE(room_name VARCHAR, total_slots_booked BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Explicit Cursor definition
    cur_rooms CURSOR FOR SELECT id, name FROM rooms WHERE is_active = TRUE;
    r_id INTEGER;
    r_name VARCHAR;
    v_count BIGINT;
BEGIN
    OPEN cur_rooms;
    LOOP
        FETCH cur_rooms INTO r_id, r_name;
        EXIT WHEN NOT FOUND;

        SELECT COUNT(*) INTO v_count
        FROM bookings b
        JOIN booking_slots bs ON b.id = bs.booking_id
        WHERE b.room_id = r_id AND b.status = 'CONFIRMED';

        room_name := r_name;
        total_slots_booked := v_count;
        RETURN NEXT;
    END LOOP;
    CLOSE cur_rooms;
END;
$$;
