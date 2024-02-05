# Hotel-Booking

## Summary

- [ERD_project.sql](ERD_project.sql) คือ table + relation ทั้งหมดของ proeject
- [gen_result_sql.py](gen_result_sql.py) เอาไว้รวมทุกอย่างใน funtions, procedures, views เอาไว้ไปก็อปไป excute ใน pgAdmin ทีเดียว

## Projet Funtion Requirement

1. The system shall allow a user to register by specifying the name, telephone number, email, and password.
     - [register_all_user](procedures\register_all_user.sql)
2. After registration, the user becomes a registered user, and the system shall allow the user to log in to use the system by specifying the email and password. The system shall allow a registered user to log out.
   - [login_user](procedures\login_user.sql)
   - [logout_user.sql](procedures\logout_user.sql)
3. After login, the system shall allow the registered user to book up to 3 nights by specifying the date and the preferred hotel. The hotel list is also provided to the user. A hotel information includes the hotel name, address, and telephone number.
   - [insert_booking_with_user_and_room](functions\insert_booking_with_user_and_room.sql)
   - [user_view_all_room](functions\user_view_all_room.sql)
4. The system shall allow the registered user to view his hotel bookings.
   - [user_view_bookings](functions\user_view_bookings.sql)
5. The system shall allow the registered user to edit his hotel bookings.
   - [user_edit_booking](procedures\user_edit_booking.sql)
6. The system shall allow the registered user to delete his hotel bookings.
   - [user_delete_booking](procedures\user_delete_booking.sql)
7. The system shall allow the admin to view any hotel bookings.
   - [admin_view_bookings](functions\admin_view_bookings.sql)
8. The system shall allow the admin to edit any hotel bookings.
   - [admin_edit_booking](procedures\admin_edit_booking.sql)
9. The system shall allow the admin to delete any hotel bookings
   - [admin_delete_booking](procedures\admin_delete_booking.sql)
10. LOGIN LOG ** additional Logs requirement from TA Aussie
    - [create_login_log](functions\create_login_log.sql)
