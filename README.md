# Campus Facility Booking System — Database Management System

## 📌 Project Overview

The **Campus Facility Booking System** is a database-driven system designed to manage the booking and utilization of campus facilities such as classrooms, lecture halls, laboratories, and meeting rooms.

The main focus of this project is the **PostgreSQL database**, which handles room management, users, time slots, bookings, availability, conflict detection, and booking-related business logic.

The database is designed using a **normalized relational schema** and demonstrates important DBMS concepts including:

* ER modeling
* Relational database design
* Primary and foreign keys
* Constraints
* Normalization up to 3NF/BCNF
* Complex SQL queries
* Stored procedures
* PL/pgSQL functions
* Triggers
* Cursors
* Transactions and ACID properties
* Data seeding and testing

---


## 🗄️ Database Design

The database consists of the following major entities:

* `roles`
* `users`
* `room_types`
* `rooms`
* `time_slots`
* `bookings`
* `booking_slots`

### Main Relationships

* A **user** belongs to a role.
* A **room** belongs to a room type.
* A **booking** is created by a user.
* A **booking** is associated with a room.
* A booking can contain multiple time slots.
* `booking_slots` establishes the many-to-many relationship between bookings and time slots.

The database uses primary keys and foreign keys to maintain **referential integrity**.

---

## 🔑 Key Database Features

### 1. Normalization

The database schema is designed to reduce redundancy and maintain data consistency.

The design considers:

* **1NF** — Atomic values
* **2NF** — No partial dependency
* **3NF** — No transitive dependency
* **BCNF** — Determinants are candidate keys

---

### 2. Stored Procedures

The database contains procedures for important booking operations.

#### Create Booking

`sp_create_booking`

Creates a booking and associates the required time slots atomically.

#### Cancel Booking

`sp_cancel_booking`

Allows a user to cancel their booking.

#### Admin Cancel Booking

`sp_admin_cancel_booking`

Allows an administrator to cancel a booking.

---

### 3. Trigger for Double-Booking Prevention

A **BEFORE INSERT trigger** is used to prevent two confirmed bookings from using the same room, date, and time slot.

The trigger checks for an existing conflicting booking and raises an exception if a conflict is detected.

This ensures that **double booking is prevented at the database level**.

---

### 4. Cursor-Based Function

The database contains:

`fn_get_room_utilization()`

This function uses a cursor to calculate and return room utilization information.

It demonstrates the use of:

* Cursor declaration
* `OPEN`
* `FETCH`
* `EXIT`
* `CLOSE`

---

### 5. Complex SQL Queries

The project demonstrates several advanced SQL concepts, including:

* CTEs
* `CROSS JOIN`
* `LEFT JOIN`
* `GROUP BY`
* `CASE`
* `COUNT`
* `ORDER BY`
* `json_agg`
* Dynamic filtering
* Parameterized queries

These queries are used for purposes such as checking room availability, viewing bookings, and analyzing room utilization.

---

## 🔄 Transaction and ACID Properties

Booking operations are designed to maintain database consistency.

The project demonstrates the four ACID properties:

* **Atomicity** — A booking operation completes fully or is rolled back.
* **Consistency** — Database constraints and triggers maintain valid data.
* **Isolation** — Concurrent transactions are handled according to PostgreSQL transaction isolation.
* **Durability** — Committed data is preserved by PostgreSQL.

---

## 🛠️ Technologies Used

### Database

* **PostgreSQL**
* **SQL**
* **PL/pgSQL**

### Supporting Technologies

* Node.js
* Express.js
* React
* Vite

The frontend and backend provide the interface to the system, while the **database contains the core relational structure and booking-related business logic**.

---

## 🚀 How to Use the Database

### Step 1 — Install PostgreSQL

Install PostgreSQL on your system and make sure the PostgreSQL server is running.

### Step 2 — Create a Database

Create a PostgreSQL database for the project.

For example:

```sql
CREATE DATABASE campus_booking;
```

### Step 3 — Run `init.sql`

Open `database/init.sql` using PostgreSQL's query tool, pgAdmin, DBeaver, or `psql`.

Run the complete script.

The script creates the required database objects such as:

* Tables
* Constraints
* Stored procedures
* Functions
* Triggers
* Related database logic

### Step 4 — Verify the Database

After execution, verify that the tables have been created:

```text
roles
users
room_types
rooms
time_slots
bookings
booking_slots
```

The included ER diagram can be used to understand the database structure.

---

## 📊 Sample Data

The project includes database seed data representing:

* User roles
* Faculty/users
* Room types
* Rooms
* Time slots
* Booking records

The report describes a larger seeded dataset used for testing booking operations and database queries.

---



## 🎯 Project Outcome

The project demonstrates how a relational database can be designed and implemented for a real-world campus facility booking system.

The major database outcomes include:

* A normalized relational schema
* Referential integrity using primary and foreign keys
* Database-level prevention of double bookings
* Atomic multi-slot booking through stored procedures
* Cursor-based room utilization analysis
* Complex SQL queries for availability and reporting
* Transaction management following ACID principles

The database serves as the core component responsible for maintaining **data integrity, consistency, and booking rules**.
