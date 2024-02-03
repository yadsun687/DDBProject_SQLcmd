--======<ADMIN USER QUERIES>==========

--for view all bookings (ADMIN)
SELECT * FROM booking;
--=====================================

--for edit bookings (ADMIN)
UPDATE booking
SET RoomId = newRoomId,
    checkInDate = newCheckInDate ,
    NumberOfBooking = newNumberOfBooking
    payType = newPayType
WHERE booking.UserID = targetUserId AND booking.BookingId = targetBookingId;
--=====================================

--for delete bookings (ADMIN)
DELETE * FROM booking
WHERE BookingId=targetBookingId AND UserId=targetUserId AND RoomId=targetRoomId;

--=====================================
--=====================================




--======<NORMAL USER QUERIES>==========

--for view all bookings (normalUser)
SELECT * FROM booking
WHERE UserId = myUserId;
--=====================================

--for edit bookings (normalUser)
UPDATE booking
SET RoomId = newRoomId,
    checkInDate = newCheckInDate ,
    NumberOfBooking = newNumberOfBooking
    payType = newPayType
WHERE booking.UserID = myUserId AND booking.RoomID = myRoomId;
--=====================================

--for delete bookings (normalUser)
DELETE * FROM booking
WHERE BookingId=myBookingId AND UserId=myUserId;
--=====================================
--=====================================
