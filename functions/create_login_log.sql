-- FUNCTION: public.create_login_log(integer, "LoginType", date)

-- DROP FUNCTION IF EXISTS public.create_login_log(integer, "LoginType", date);

CREATE OR REPLACE FUNCTION public.create_login_log(
	user_id integer,
	login_type "LoginType",
	login_date_time date)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	INSERT INTO public."LoginLog"("Type", "Date-time", "UserID")
	VALUES (login_type, CURRENT_DATE, user_id);
END;	
$BODY$;