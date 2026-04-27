-- DDL For My Tables
CREATE OR REPLACE TABLE BRONZE_HOSTS (
    host_id NUMBER,
    host_name STRING,
    host_since DATE,
    host_location STRING,
    is_superhost BOOLEAN,
    response_rate NUMBER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    avg_host_rating DECIMAL(3,2),
    PRIMARY KEY (host_id)
);

CREATE OR REPLACE TABLE BRONZE_LISTINGS (
    listing_id NUMBER,
    host_id NUMBER,
    property_type STRING,
    room_type STRING,
    city STRING,
    country STRING,
    accommodates NUMBER,
    bedrooms NUMBER,
    bathrooms NUMBER,
    price_per_night DECIMAL(10, 2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (listing_id)
);

CREATE OR REPLACE TABLE BRONZE_BOOKINGS (
    booking_id STRING,
    listing_id NUMBER,
    booking_date TIMESTAMP,
    nights_booked NUMBER,
    booking_amount DECIMAL(10, 2),
    cleaning_fee DECIMAL(10, 2),
    service_fee DECIMAL(10, 2),
    cancellation_fee DECIMAL(10, 2),
    booking_status STRING,
    stay_start_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (booking_id)
);