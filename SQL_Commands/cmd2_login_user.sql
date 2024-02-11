CREATE OR REPLACE PROCEDURE login_user(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID and the last logout timestamp based on the provided email and password
    SELECT AU.userID INTO user_id
    FROM ALL_USER AS AU
    WHERE AU.Useremail = p_user_email AND AU.UserPassword = p_user_password;

    IF user_id IS NOT NULL AND user_id IN (SELECT userid FROM normal_user) AND user_id NOT IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        -- Insert log entry
        INSERT INTO logs(logid, login, logout, userid)
        VALUES (COALESCE((SELECT MAX(logid) + 1 FROM logs), 1), CURRENT_TIMESTAMP, NULL, user_id)
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful login
        RAISE NOTICE 'User with email % logged in successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful login
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user, or already logged in';
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE logout_user(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID and the last logout timestamp based on the provided email and password
    SELECT AU.userID INTO user_id
    FROM ALL_USER AS AU
    WHERE AU.Useremail = p_user_email AND AU.UserPassword = p_user_password;

    IF user_id IS NOT NULL AND user_id IN (SELECT userid FROM normal_user) AND user_id IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        UPDATE logs
        SET logout = CURRENT_TIMESTAMP
        WHERE userid = user_id AND logout IS NULL
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful logout
        RAISE NOTICE 'User with email % logged out successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful logout
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user, or already logged out';
    END IF;
END;
$$;


-- Test login_user procedure
CALL login_user('john.doe@example.com', 'password123');

-- Test logout_user procedure
CALL logout_user('john.doe@example.com', 'password123');
