--for view all bookings (ADMIN)
SELECT * FROM booking;
--========================

--for edit bookings (ADMIN)
CREATE OR REPLACE FUNCTION editBooking(
    BID INT,
    RID INT,
    newUserID INT,
    CiDate DATE,
    BNumber INT,
    Ptype VARCHAR(100)) 
    
    RETURNS BookingID
    LANGUAGE plpgsql
    $$
    BEGIN
        UPDATE booking
        SET RoomID = RID,
            UserID = newUserID,
            checkInDate = CiDate,
            bookingNumber = BNumber,
            paytype = Ptype
        WHERE booking.BookingID = BID AND
              booking.RoomID = RID; 

    END;
    &&
--========================

--for view all bookings (normalUser)
SELECT * FROM booking
WHERE UserID = 