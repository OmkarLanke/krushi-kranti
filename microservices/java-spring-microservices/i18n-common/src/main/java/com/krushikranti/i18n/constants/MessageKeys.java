package com.krushikranti.i18n.constants;

/**
 * Message keys for internationalization.
 * These constants map to keys in messages.properties files.
 */
public final class MessageKeys {

    private MessageKeys() {
        // Utility class - prevent instantiation
    }

    // Auth - Registration
    public static final String AUTH_REGISTRATION_OTP_SENT = "auth.registration.otp.sent";
    public static final String AUTH_REGISTRATION_COMPLETED = "auth.registration.completed";
    public static final String AUTH_REGISTRATION_FAILED = "auth.registration.failed";

    // Auth - Login
    public static final String AUTH_LOGIN_SUCCESS = "auth.login.success";
    public static final String AUTH_LOGIN_FAILED = "auth.login.failed";
    public static final String AUTH_LOGIN_INVALID_EMAIL_PASSWORD = "auth.login.invalid.email.password";
    public static final String AUTH_LOGIN_INVALID_PHONE_OTP = "auth.login.invalid.phone.otp";
    public static final String AUTH_LOGIN_PROVIDE_CREDENTIALS = "auth.login.provide.credentials";
    public static final String AUTH_LOGIN_OTP_SENT = "auth.login.otp.sent";

    // Auth - OTP
    public static final String AUTH_OTP_SENT = "auth.otp.sent";
    public static final String AUTH_OTP_VERIFIED = "auth.otp.verified";
    public static final String AUTH_OTP_INVALID = "auth.otp.invalid";
    public static final String AUTH_OTP_EXPIRED = "auth.otp.expired";
    public static final String AUTH_OTP_RESENT = "auth.otp.resent";

    // Auth - Token
    public static final String AUTH_TOKEN_INVALID = "auth.token.invalid";
    public static final String AUTH_TOKEN_EXPIRED = "auth.token.expired";
    public static final String AUTH_TOKEN_REFRESHED = "auth.token.refreshed";

    // Auth - User
    public static final String AUTH_USER_NOT_FOUND = "auth.user.not.found";
    public static final String AUTH_USER_ALREADY_EXISTS = "auth.user.already.exists";
    public static final String AUTH_USER_RETRIEVED = "auth.user.retrieved";

    // Auth - Logout
    public static final String AUTH_LOGOUT_SUCCESS = "auth.logout.success";

    // Validation
    public static final String VALIDATION_PHONE_REQUIRED = "validation.phone.required";
    public static final String VALIDATION_EMAIL_REQUIRED = "validation.email.required";
    public static final String VALIDATION_OTP_REQUIRED = "validation.otp.required";

    // Error
    public static final String ERROR_INTERNAL = "error.internal";
    public static final String ERROR_UNAUTHORIZED = "error.unauthorized";
    public static final String ERROR_BAD_REQUEST = "error.bad.request";

    // Subscription
    public static final String SUBSCRIPTION_STATUS_RETRIEVED = "subscription.status.retrieved";
    public static final String SUBSCRIPTION_USER_SUBSCRIBED = "subscription.user.subscribed";
    public static final String SUBSCRIPTION_USER_NOT_SUBSCRIBED = "subscription.user.not.subscribed";
    public static final String SUBSCRIPTION_PAYMENT_INITIATED = "subscription.payment.initiated";
    public static final String SUBSCRIPTION_PAYMENT_SUCCESS = "subscription.payment.success";
    public static final String SUBSCRIPTION_PAYMENT_FAILED = "subscription.payment.failed";
    public static final String SUBSCRIPTION_ALREADY_ACTIVE = "subscription.already.active";
    public static final String SUBSCRIPTION_EXPIRED = "subscription.expired";

    // Farmer Profile
    public static final String FARMER_PROFILE_CREATED = "farmer.profile.created";
    public static final String FARMER_PROFILE_UPDATED = "farmer.profile.updated";
    public static final String FARMER_PROFILE_RETRIEVED = "farmer.profile.retrieved";
    public static final String FARMER_PROFILE_NOT_FOUND = "farmer.profile.not.found";
    public static final String FARMER_ADDRESS_LOOKUP_SUCCESS = "farmer.address.lookup.success";

    // Farm
    public static final String FARM_CREATED = "farm.created";
    public static final String FARM_UPDATED = "farm.updated";
    public static final String FARM_DELETED = "farm.deleted";
    public static final String FARM_RETRIEVED = "farm.retrieved";
    public static final String FARM_NOT_FOUND = "farm.not.found";
    public static final String FARMS_RETRIEVED = "farms.retrieved";

    // Crop
    public static final String CROP_CREATED = "crop.created";
    public static final String CROP_UPDATED = "crop.updated";
    public static final String CROP_DELETED = "crop.deleted";
    public static final String CROP_RETRIEVED = "crop.retrieved";
    public static final String CROP_NOT_FOUND = "crop.not.found";
    public static final String CROPS_RETRIEVED = "crops.retrieved";
}

