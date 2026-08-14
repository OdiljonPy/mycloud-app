Swagger UI
http://192.168.100.149:8000/swagger/?format=openapi
Explore
My Cloud project API
v1
[ Base URL: 192.168.100.149:8000/api/v1 ]
http://192.168.100.149:8000/swagger/?format=openapi
API for My Cloud project

Contact the developer
BSD License
Schemes

http
Django Login
Authorize
Filter by tag
User


PATCH
/authentication/users/disable/
authentication_users_disable_partial_update


POST
/authentication/users/login/
authentication_users_login_create


GET
/authentication/users/me/
authentication_users_me_list


POST
/authentication/users/otp/resend/
authentication_users_otp_resend_create


POST
/authentication/users/otp/verify/
authentication_users_otp_verify_create


POST
/authentication/users/password/forgot/
authentication_users_password_forgot_create


POST
/authentication/users/password/resend/
authentication_users_password_resend_create


PATCH
/authentication/users/password/reset/
authentication_users_password_reset_partial_update


POST
/authentication/users/password/verify/
authentication_users_password_verify_create


POST
/authentication/users/register/
authentication_users_register_create


POST
/authentication/users/token-refresh/
authentication_users_token-refresh_create


PATCH
/authentication/users/{id}/
authentication_users_partial_update

Landing


POST
/base/contact/
base_contact_create

Contact create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"email": "user@example.com",
"theme": "string",
"message": "string"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/base/contact/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"email": "user@example.com",
"theme": "string",
"message": "string"
}'
Request URL
http://192.168.100.149:8000/api/v1/base/contact/
Server response
Code	Details
201
Response body
Download
{
"id": 774,
"email": "user@example.com",
"theme": "string",
"message": "string"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
allow: POST,OPTIONS
content-language: ru
content-length: 73
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:26:05 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept,Accept-Language,origin
x-content-type-options: nosniff
x-frame-options: DENY
Request duration
154 ms
Responses
Code	Description
201
Example Value
Model
Contact{
id	integer
title: ID
readOnly: true
email*	string($email)
title: Email
maxLength: 254
minLength: 1
theme*	string
title: Theme
maxLength: 500
minLength: 1
message*	string
title: Message
minLength: 1

}

GET
/storage/plan/
storage_plan_list

Price list

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/storage/plan/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/storage/plan/
Server response
Code	Details
200
Response body
Download
[
{
"id": 10,
"name": "Корпоративный",
"price": "499900.00",
"billing_period": "monthly",
"storage": 21990232555520,
"is_popular": false,
"items": [
{
"id": 96,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 94,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 95,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 93,
"feature": "Team activity audit log",
"is_available": true
},
{
"id": 92,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 91,
"feature": "Offline access",
"is_available": true
},
{
"id": 90,
"feature": "Ransomware detection & rollback",
"is_available": true
}
]
},
{
"id": 9,
"name": "Командный",
"price": "249900.00",
"billing_period": "monthly",
"storage": 10995116277760,
"is_popular": false,
"items": [
{
"id": 88,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 89,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 87,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 86,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 85,
"feature": "Admin usage dashboard",
"is_available": true
},
{
"id": 84,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 83,
"feature": "Offline access",
"is_available": true
},
{
"id": 81,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 82,
"feature": "Shared folders with team members",
"is_available": true
}
]
},
{
"id": 8,
"name": "Бизнес",
"price": "149900.00",
"billing_period": "monthly",
"storage": 5497558138880,
"is_popular": false,
"items": [
{
"id": 80,
"feature": "Dedicated account manager",
"is_available": true
},
{
"id": 78,
"feature": "Custom branding on shared folders",
"is_available": true
},
{
"id": 79,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 77,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 76,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 74,
"feature": "Ransomware detection & rollback",
"is_available": true
},
{
"id": 75,
"feature": "Admin usage dashboard",
"is_available": true
}
]
},
{
"id": 7,
"name": "Про",
"price": "79900.00",
"billing_period": "monthly",
"storage": 1099511627776,
"is_popular": false,
"items": [
{
"id": 73,
"feature": "Admin usage dashboard",
"is_available": true
},
{
"id": 72,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 71,
"feature": "Team activity audit log",
"is_available": true
},
{
"id": 70,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 69,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 68,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 67,
"feature": "Custom branding on shared folders",
"is_available": true
},
{
"id": 66,
"feature": "Offline access",
"is_available": true
},
{
"id": 65,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 64,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 62,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 63,
"feature": "Ransomware detection & rollback",
"is_available": true
}
]
},
{
"id": 6,
"name": "Семейный",
"price": "99900.00",
"billing_period": "monthly",
"storage": 2199023255552,
"is_popular": false,
"items": [
{
"id": 61,
"feature": "Dedicated account manager",
"is_available": true
},
{
"id": 60,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 59,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 58,
"feature": "Offline access",
"is_available": true
},
{
"id": 57,
"feature": "Unlimited devices",
"is_available": true
},
{
"id": 56,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 55,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 54,
"feature": "Ransomware detection & rollback",
"is_available": true
},
{
"id": 53,
"feature": "Team activity audit log",
"is_available": true
},
{
"id": 52,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 51,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 50,
"feature": "Admin usage dashboard",
"is_available": true
},
{
"id": 49,
"feature": "Shared folders with team members",
"is_available": true
}
]
},
{
"id": 5,
"name": "Плюс",
"price": "39900.00",
"billing_period": "monthly",
"storage": 214748364800,
"is_popular": true,
"items": [
{
"id": 48,
"feature": "Unlimited devices",
"is_available": true
},
{
"id": 47,
"feature": "Ransomware detection & rollback",
"is_available": true
},
{
"id": 46,
"feature": "Admin usage dashboard",
"is_available": true
},
{
"id": 45,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 44,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 43,
"feature": "Custom branding on shared folders",
"is_available": true
},
{
"id": 42,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 41,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 40,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 39,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 38,
"feature": "Dedicated account manager",
"is_available": true
},
{
"id": 37,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 36,
"feature": "Offline access",
"is_available": true
}
]
},
{
"id": 4,
"name": "Базовый",
"price": "19900.00",
"billing_period": "monthly",
"storage": 53687091200,
"is_popular": false,
"items": [
{
"id": 35,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 34,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 33,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 32,
"feature": "Custom branding on shared folders",
"is_available": true
},
{
"id": 31,
"feature": "Unlimited devices",
"is_available": true
},
{
"id": 30,
"feature": "Offline access",
"is_available": true
},
{
"id": 29,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 28,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 27,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 26,
"feature": "Team activity audit log",
"is_available": true
},
{
"id": 25,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 24,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 23,
"feature": "Dedicated account manager",
"is_available": true
}
]
},
{
"id": 3,
"name": "Стартовый",
"price": "9900.00",
"billing_period": "monthly",
"storage": 21474836480,
"is_popular": false,
"items": [
{
"id": 21,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 22,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 20,
"feature": "Offline access",
"is_available": true
},
{
"id": 19,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 17,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 18,
"feature": "Unlimited devices",
"is_available": true
}
]
},
{
"id": 2,
"name": "Студенческий",
"price": "14900.00",
"billing_period": "monthly",
"storage": 107374182400,
"is_popular": false,
"items": [
{
"id": 16,
"feature": "Dedicated account manager",
"is_available": true
},
{
"id": 14,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 15,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 13,
"feature": "Custom branding on shared folders",
"is_available": true
},
{
"id": 12,
"feature": "Password-protected share links",
"is_available": true
},
{
"id": 11,
"feature": "File versioning (30 days)",
"is_available": true
},
{
"id": 10,
"feature": "Automatic photo backup",
"is_available": true
},
{
"id": 9,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 8,
"feature": "Admin usage dashboard",
"is_available": true
}
]
},
{
"id": 1,
"name": "Бесплатный",
"price": "0.00",
"billing_period": "free",
"storage": 5368709120,
"is_popular": false,
"items": [
{
"id": 7,
"feature": "Bulk download as ZIP",
"is_available": true
},
{
"id": 6,
"feature": "Shared folders with team members",
"is_available": true
},
{
"id": 5,
"feature": "Advanced sharing permissions",
"is_available": true
},
{
"id": 4,
"feature": "Priority customer support",
"is_available": true
},
{
"id": 3,
"feature": "Team activity audit log",
"is_available": true
},
{
"id": 2,
"feature": "Two-factor authentication",
"is_available": true
},
{
"id": 1,
"feature": "Admin usage dashboard",
"is_available": true
}
]
}
]
Response headers
allow: GET,HEAD,OPTIONS
content-language: ru
content-length: 7835
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:26:12 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept,Accept-Language,origin
x-content-type-options: nosniff
x-frame-options: DENY
Request duration
162 ms
Responses
Code	Description
200
Example Value
Model
Plan{
id	integer
title: Id
readOnly: true
name	string
title: Name
readOnly: true
minLength: 1
price	string($decimal)
title: Price
readOnly: true
billing_period	string
title: Billing period
readOnly: true
minLength: 1
storage	integer
title: Storage
readOnly: true
is_popular	boolean
title: Is popular
readOnly: true
items	[
readOnly: true
PlanItem{
id	integer
title: Id
readOnly: true
feature	string
title: Feature
readOnly: true
minLength: 1
is_available	boolean
title: Is available
readOnly: true

}]

}
Content


POST
/content/bulk-download/
content_bulk-download_create

Bulk download as a hierarchical ZIP file

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"file_ids": [],
"folder_ids": []
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/bulk-download/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"file_ids": [],
"folder_ids": []
}'
Request URL
http://192.168.100.149:8000/api/v1/content/bulk-download/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:26:36 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
FavouriteFolder


GET
/content/favourite-file/
content_favourite-file_list

Favourite file list

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/favourite-file/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/favourite-file/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:26:42 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FavouriteFileList{
id*	integer
title: Id
user*	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file*	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
[ pending, completed, failed ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
[ not_required, pending, processing, completed, failed ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}

}

POST
/content/favourite-file/
content_favourite-file_create

Favourite file create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"file": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/favourite-file/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"file": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/favourite-file/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:27:20 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
201
Example Value
Model
FavouriteFileList{
id*	integer
title: Id
user*	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file*	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
Array [ 3 ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
Array [ 5 ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}

}

GET
/content/favourite-file/all/
content_favourite-file_all_list

Favourite file all

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/favourite-file/all/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/favourite-file/all/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:28:32 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FavouriteFileList{
id*	integer
title: Id
user*	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file*	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
[ pending, completed, failed ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
[ not_required, pending, processing, completed, failed ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}

}

DELETE
/content/favourite-file/{id}/
content_favourite-file_delete

Favourite file delete

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/content/favourite-file/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/favourite-file/1/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:29:02 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
204
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
File


POST
/content/files/check-duplicate/
content_files_check-duplicate_create

API to check for duplicates files

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"files": [
{
"name": "string",
"size": 0,
"type": "string",
"uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
]
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/files/check-duplicate/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"files": [
{
"name": "string",
"size": 0,
"type": "string",
"uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
]
}'
Request URL
http://192.168.100.149:8000/api/v1/content/files/check-duplicate/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:25:21 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FilesCheckDuplicateResponse{
uuid*	string($uuid)
title: Uuid
is_duplicate*	boolean
title: Is duplicate

}

POST
/content/files/tus-webhook/
content_files_tus-webhook_create

Webhook endpoint for tusd to notify about upload events.This endpoint will be called by tusd when an upload is created, completed, or terminated. We will handle these events to update our File records accordingly.

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/files/tus-webhook/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d ''
Request URL
http://192.168.100.149:8000/api/v1/content/files/tus-webhook/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:25:28 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/files/{id}/download/
content_files_download_list

Endpoint to download a file. The file will be streamed from MinIO to the client.

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/files/1/download/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/files/1/download/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:25:33 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FileDownload{
url*	string
title: Url
minLength: 1
name*	string
title: Name
minLength: 1
mime_type*	string
title: Mime type
minLength: 1
size*	integer
title: Size
captured_at*	string($date-time)
title: Captured at

}

GET
/content/files/{id}/hls/master.m3u8
HLS master playlist
content_files_hls_master.m3u8_list


GET
/content/files/{id}/hls/{quality}/playlist.m3u8
HLS variant playlist (по качеству)
content_files_hls_playlist.m3u8_list


GET
/content/files/{id}/hls/{quality}/{filename}
HLS сегмент (.ts / .m3u8)
content_files_hls_read


GET
/content/files/{id}/preview/
content_files_preview_list

Endpoint to preview a meida file. The file will be streamed from MinIO to the client.

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/files/1/preview/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/files/1/preview/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:25:42 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FilePreview{
url*	string
title: Url
minLength: 1
x-nullable: true
name*	string
title: Name
minLength: 1
mime_type*	string
title: Mime type
minLength: 1
size*	integer
title: Size
captured_at*	string($date-time)
title: Captured at
preview_status*	string
title: Preview status
minLength: 1
preview_type*	string
title: Preview type
preview_meta	Preview meta{

}

}

GET
/content/gallery/
content_gallery_list

Taking files by captured date.

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/gallery/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/gallery/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:29:18 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
File{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
size	integer
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	string
title: Mime type
maxLength: 255
minio_path	string
title: Minio path
maxLength: 500
upload_status	string
title: Upload status
Enum:
[ pending, completed, failed ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	string($date-time)
title: Captured at
is_favourite	boolean
title: Is favourite
readOnly: true
thumbnail_path	string
title: Thumbnail path
readOnly: true
preview_status	string
title: Preview status
Enum:
[ not_required, pending, processing, completed, failed ]
preview_type	string
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	string
title: Video variants
readOnly: true

}

GET
/content/recent-files/
content_recent-files_list

Recent files

Parameters
Cancel
Name	Description
size
integer
(query)
Quantity of recent files

1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/recent-files/?size=1' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/recent-files/?size=1
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:29:35 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
File{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
size	integer
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	string
title: Mime type
maxLength: 255
minio_path	string
title: Minio path
maxLength: 500
upload_status	string
title: Upload status
Enum:
Array [ 3 ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	string($date-time)
title: Captured at
is_favourite	boolean
title: Is favourite
readOnly: true
thumbnail_path	string
title: Thumbnail path
readOnly: true
preview_status	string
title: Preview status
Enum:
Array [ 5 ]
preview_type	string
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	string
title: Video variants
readOnly: true

}
Folder


DELETE
/content/folder-file/delete/
content_folder-file_delete_delete

Folder file delete

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"files": [],
"folders": [],
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_all": true
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/content/folder-file/delete/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"files": [],
"folders": [],
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_all": true
}'
Request URL
http://192.168.100.149:8000/api/v1/content/folder-file/delete/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:30:20 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

PATCH
/content/folder-file/move/
content_folder-file_move_partial_update

Folder file move

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"target_folder": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"files": [],
"folders": [],
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_all": true
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'PATCH' \
'http://192.168.100.149:8000/api/v1/content/folder-file/move/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"target_folder": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"files": [],
"folders": [],
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_all": true
}'
Request URL
http://192.168.100.149:8000/api/v1/content/folder-file/move/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:30:27 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

PATCH
/content/folder-file/rename/
content_folder-file_rename_partial_update

Folder file rename

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"type": "string",
"name": "string"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'PATCH' \
'http://192.168.100.149:8000/api/v1/content/folder-file/rename/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"type": "string",
"name": "string"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/folder-file/rename/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:30:44 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/folder/
content_folder_list

Folder list

Parameters
Cancel
Name	Description
search
string
(query)
1
type
string
(query)

all
start_date
string($date)
(query)
1
end_date
string($date)
(query)
2
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/folder/?search=1&type=all&start_date=1&end_date=2' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/folder/?search=1&type=all&start_date=1&end_date=2
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:30:57 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
Folder{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
parent	string($uuid)
title: Parent
x-nullable: true
is_sync	boolean
title: Is sync
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

POST
/content/folder/
content_folder_create

Folder create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"name": "string",
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_sync": true
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/folder/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"name": "string",
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"is_sync": true
}'
Request URL
http://192.168.100.149:8000/api/v1/content/folder/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:08 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
201
Example Value
Model
Folder{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
parent	string($uuid)
title: Parent
x-nullable: true
is_sync	boolean
title: Is sync
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

GET
/content/folder/{id}/
content_folder_read

Folder detail

Parameters
Cancel
Name	Description
search
string
(query)
1
type
string
(query)

all
start_date
string($date)
(query)
1
end_date
string($date)
(query)
1
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/folder/1/?search=1&type=all&start_date=1&end_date=1' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/folder/1/?search=1&type=all&start_date=1&end_date=1
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:19 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/folder/{id}/breadcrumb/
content_folder_breadcrumb_list

Folder breadcrumb

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/folder/1/breadcrumb/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/folder/1/breadcrumb/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:31 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FolderDetail{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
parent	string($uuid)
title: Parent
x-nullable: true
breadcrumbs	string
title: Breadcrumbs
readOnly: true

}
Info


POST
/content/info/
content_info_create

Get info for a single file or folder.

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"type": "file"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/info/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
"type": "file"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/info/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:41 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

POST
/content/selection-info/
content_selection-info_create

Get aggregated info for selected files and folders.

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"file_ids": [],
"folder_ids": [],
"is_all": false,
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/selection-info/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"file_ids": [],
"folder_ids": [],
"is_all": false,
"parent": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/selection-info/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:51 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
SelectionInfo{
total_size*	integer
title: Total size
file_count*	integer
title: File count
folder_count*	integer
title: Folder count

}
PinnedFolder


GET
/content/pinned-folders/
content_pinned-folders_list

Pinned folders list

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/pinned-folders/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/pinned-folders/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:31:58 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
PinnedFolderList{
folder*	Folder{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
parent	Parentstring($uuid)
title: Parent
x-nullable: true
is_sync	Is syncboolean
title: Is sync
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true

}
user*	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
created_at*	string($date-time)
title: Created at

}

POST
/content/pinned-folders/
content_pinned-folders_create

Pinned folders create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"folder": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/pinned-folders/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"folder": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/pinned-folders/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:32:13 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
PinnedFolderList{
folder*	Folder{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
parent	Parentstring($uuid)
title: Parent
x-nullable: true
is_sync	Is syncboolean
title: Is sync
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true

}
user*	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
created_at*	string($date-time)
title: Created at

}

DELETE
/content/pinned-folders/{id}/
content_pinned-folders_delete

Pinned folders delete

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/content/pinned-folders/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/pinned-folders/1/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:32:26 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
204
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
ShareRequest


POST
/content/share-request-permission/
content_share-request-permission_create

Share request permission create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"link": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/share-request-permission/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"link": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request-permission/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:32:32 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestPermissionList{
id*	integer
title: Id
request	ShareRequestList{
id*	Idinteger
title: Id
name*	Namestring
title: Name
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
link*	Linkstring($uuid)
title: Link

}
requester	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
status*	string
title: Status
Enum:
Array [ 3 ]

}

PATCH
/content/share-request-permission/{id}/
content_share-request-permission_partial_update

Share request permission's status update

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"status": "pending"
}
Cancel
Parameter content type

application/json
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'PATCH' \
'http://192.168.100.149:8000/api/v1/content/share-request-permission/1/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"status": "pending"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request-permission/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:32:50 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestPermissionList{
id*	integer
title: Id
request	ShareRequestList{
id*	Idinteger
title: Id
name*	Namestring
title: Name
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
link*	Linkstring($uuid)
title: Link

}
requester	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
status*	string
title: Status
Enum:
Array [ 3 ]

}

GET
/content/share-request/
content_share-request_list

Share request's list

Parameters
Cancel
Name	Description
name
string
(query)
Filter share requests by name

1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/share-request/?name=1' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request/?name=1
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:33:06 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestList{
id*	integer
title: Id
name*	string
title: Name
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
link*	string($uuid)
title: Link

}

POST
/content/share-request/
content_share-request_create

Share request create

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"name": "string",
"files": [
"3fa85f64-5717-4562-b3fc-2c963f66afa6"
],
"folders": [
"3fa85f64-5717-4562-b3fc-2c963f66afa6"
]
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/share-request/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"name": "string",
"files": [
"3fa85f64-5717-4562-b3fc-2c963f66afa6"
],
"folders": [
"3fa85f64-5717-4562-b3fc-2c963f66afa6"
]
}'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:33:20 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestList{
id*	integer
title: Id
name*	string
title: Name
minLength: 1
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
link*	string($uuid)
title: Link

}

POST
/content/share-request/check-permission/
content_share-request_check-permission_create

Share request check permission

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"link": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/share-request/check-permission/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"link": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request/check-permission/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:34:48 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestCheckPermissionOwner{
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}

}

GET
/content/share-request/{id}/
content_share-request_read

Share request detail

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/share-request/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/share-request/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:34:56 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ShareRequestDetail{
id*	integer
title: Id
name*	string
title: Name
minLength: 1
link*	string($uuid)
title: Link
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
items	[
readOnly: true
ShareRequestItem{
id*	Id[...]
request*	ShareRequestList{
id*	integer
title: Id
name*	string
title: Name
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
link*	string($uuid)
title: Link

}
file*	File{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
size	integer
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	string
title: Mime type
maxLength: 255
minio_path	string
title: Minio path
maxLength: 500
upload_status	string
title: Upload status
Enum:
[ pending, completed, failed ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	string($date-time)
title: Captured at
is_favourite	boolean
title: Is favourite
readOnly: true
thumbnail_path	string
title: Thumbnail path
readOnly: true
preview_status	string
title: Preview status
Enum:
Array [ 5 ]
preview_type	string
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	string
title: Video variants
readOnly: true

}
folder*	Folder{
id	string($uuid)
title: Id
readOnly: true
name*	string
title: Name
maxLength: 255
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
parent	string($uuid)
title: Parent
x-nullable: true
is_sync	boolean
title: Is sync
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

}]
permissions	[
readOnly: true
ShareRequestPermissionList{
id*	integer
title: Id
request	ShareRequestList{
id*	integer
title: Id
name*	string
title: Name
minLength: 1
owner	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
link*	string($uuid)
title: Link

}
requester	User{
id	integer
title: ID
readOnly: true
full_name*	string
title: Full name
maxLength: 255
minLength: 1
phone_number*	string
title: Phone number
maxLength: 14
minLength: 1

}
status*	string
title: Status
Enum:
[ pending, approved, rejected ]

}]

}
Share


GET
/content/shared-by-me/
content_shared-by-me_list

List all shares you've granted

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-by-me/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-by-me/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:39:48 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FileShare{
id	integer
title: ID
readOnly: true
shared_with	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
Array [ 3 ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
Array [ 5 ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}
folder	Folder{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
parent	Parentstring($uuid)
title: Parent
x-nullable: true
is_sync	Is syncboolean
title: Is sync
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true

}
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

POST
/content/shared-by-me/
content_shared-by-me_create

Share files/folders with a user by phone number

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"phone_numbers": [
"string"
],
"file_ids": [],
"folder_ids": []
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/content/shared-by-me/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"phone_numbers": [
"string"
],
"file_ids": [],
"folder_ids": []
}'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-by-me/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:39:56 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
201
Example Value
Model
FileShare{
id	integer
title: ID
readOnly: true
shared_with	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
Array [ 3 ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
Array [ 5 ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}
folder	Folder{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
parent	Parentstring($uuid)
title: Parent
x-nullable: true
is_sync	Is syncboolean
title: Is sync
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true

}
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

DELETE
/content/shared-by-me/
content_shared-by-me_delete

Revoke specific file/folder shares

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/content/shared-by-me/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-by-me/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:40:04 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
FileShare{
id	integer
title: ID
readOnly: true
shared_with	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
file	File{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
size	Sizeinteger
title: Size
maximum: 9223372036854776000
minimum: -9223372036854776000
mime_type	Mime typestring
title: Mime type
maxLength: 255
minio_path	Minio pathstring
title: Minio path
maxLength: 500
upload_status	Upload statusstring
title: Upload status
Enum:
Array [ 3 ]
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true
captured_at	Captured atstring($date-time)
title: Captured at
is_favourite	Is favouriteboolean
title: Is favourite
readOnly: true
thumbnail_path	Thumbnail pathstring
title: Thumbnail path
readOnly: true
preview_status	Preview statusstring
title: Preview status
Enum:
Array [ 5 ]
preview_type	Preview typestring
title: Preview type
maxLength: 20
preview_meta	Preview meta{

}
video_variants	Video variantsstring
title: Video variants
readOnly: true

}
folder	Folder{
id	Idstring($uuid)
title: Id
readOnly: true
name*	Namestring
title: Name
maxLength: 255
minLength: 1
owner	User{
id	ID[...]
full_name*	Full name[...]
phone_number*	Phone number[...]

}
parent	Parentstring($uuid)
title: Parent
x-nullable: true
is_sync	Is syncboolean
title: Is sync
created_at	Created atstring($date-time)
title: Created at
readOnly: true
x-nullable: true

}
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true

}

GET
/content/shared-by-me/users/
content_shared-by-me_users_list

List users to whom i share file

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-by-me/users/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-by-me/users/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:40:14 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
SharedByMeUser{
shared_with	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
shared_count*	integer
title: Shared count

}

GET
/content/shared-by-me/{folder_id}/
content_shared-by-me_read

Shared by me folders

Parameters
Cancel
Name	Description
folder_id *
string
(path)
1
Execute
Responses
Response content type

application/json
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/shared-by-me/{user_id}/
content_shared-by-me_read

View files/folders shared by me to specific user

Parameters
Cancel
Name	Description
user_id *
string
(path)
11
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-by-me/11/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-by-me/11/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:40:33 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/shared-by-me/{user_id}/folder/{folder_id}/
content_shared-by-me_folder_read

View files/folders shared by me to specific user

Parameters
Cancel
Name	Description
user_id *
string
(path)
1
folder_id *
string
(path)
1
Execute
Responses
Response content type

application/json
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/shared-with-me/
content_shared-with-me_list

List users who shared files with me

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-with-me/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-with-me/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:40:47 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
SharedWithMeUser{
owner	User{
id	IDinteger
title: ID
readOnly: true
full_name*	Full namestring
title: Full name
maxLength: 255
minLength: 1
phone_number*	Phone numberstring
title: Phone number
maxLength: 14
minLength: 1

}
shared_count*	integer
title: Shared count

}

GET
/content/shared-with-me/{user_id}/
content_shared-with-me_read

View files/folders shared by a specific user

Parameters
Cancel
Name	Description
user_id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-with-me/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-with-me/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:41:00 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

GET
/content/shared-with-me/{user_id}/folder/{folder_id}/
content_shared-with-me_folder_read

View files/folders shared by a specific user

Parameters
Cancel
Name	Description
user_id *
string
(path)
1
folder_id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/shared-with-me/1/folder/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/shared-with-me/1/folder/1/
Server response
Code	Details
404
Undocumented
Error: Not Found

Response body
Download
{
"message": "Not found.",
"message_key": "not_found"
}
Response headers
content-language: ru
content-length: 53
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:41:10 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
Statistics


GET
/content/statistics/
content_statistics_list

Getting necessary statistics.

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/content/statistics/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/content/statistics/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:25:06 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
Notifications


GET
/notifications/
notifications_list

Получить список уведомлений пользователя с пагинацией и фильтрацией

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/notifications/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/notifications/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:41:19 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
Notification{
id	integer
title: ID
readOnly: true
Notification ID

type	string
title: Type
readOnly: true
Notification type key

Enum:
[ subscription_expiry_warning, subscription_expired, subscription_renewed, subscription_downgraded, payment_success, payment_failed, card_declined, file_shared, file_share_revoked, share_request_received, share_request_approved, share_request_rejected, system_announcement, storage_warning, storage_full ]
body	Body{
description:
Notification data (JSON)


}
is_read	boolean
title: Is read
readOnly: true
Whether the notification is read

priority	string
title: Priority
readOnly: true
Priority (internal code)

Enum:
Array [ 3 ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
Creation date

updated_at	string($date-time)
title: Updated at
readOnly: true
x-nullable: true
Update date


}

POST
/notifications/mark-all-read/
notifications_mark-all-read_create

Отметить все уведомления как прочитанные

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/notifications/mark-all-read/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d ''
Request URL
http://192.168.100.149:8000/api/v1/notifications/mark-all-read/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:22:47 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
UnreadCount{
unread_count*	integer
title: Unread count
Number of unread notifications


}

GET
/notifications/unread-count/
notifications_unread-count_list

Получить количество непрочитанных уведомлений

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/notifications/unread-count/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/notifications/unread-count/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:22:52 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
UnreadCount{
unread_count*	integer
title: Unread count
Number of unread notifications


}

GET
/notifications/{id}/
notifications_read

Получить детальную информацию об уведомлении

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/notifications/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/notifications/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:03 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
Notification{
id	integer
title: ID
readOnly: true
Notification ID

type	string
title: Type
readOnly: true
Notification type key

Enum:
[ subscription_expiry_warning, subscription_expired, subscription_renewed, subscription_downgraded, payment_success, payment_failed, card_declined, file_shared, file_share_revoked, share_request_received, share_request_approved, share_request_rejected, system_announcement, storage_warning, storage_full ]
body	Body{
description:
Notification data (JSON)


}
is_read	boolean
title: Is read
readOnly: true
Whether the notification is read

priority	string
title: Priority
readOnly: true
Priority (internal code)

Enum:
Array [ 3 ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
Creation date

updated_at	string($date-time)
title: Updated at
readOnly: true
x-nullable: true
Update date


}

DELETE
/notifications/{id}/
notifications_delete

Удалить уведомление

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/notifications/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/notifications/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:13 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
204
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}

POST
/notifications/{id}/read/
notifications_read_create

Отметить уведомление как прочитанное

Parameters
Cancel
Name	Description
id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/notifications/1/read/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d ''
Request URL
http://192.168.100.149:8000/api/v1/notifications/1/read/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:20 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
Notification{
id	integer
title: ID
readOnly: true
Notification ID

type	string
title: Type
readOnly: true
Notification type key

Enum:
Array [ 15 ]
body	Body{
description:
Notification data (JSON)


}
is_read	boolean
title: Is read
readOnly: true
Whether the notification is read

priority	string
title: Priority
readOnly: true
Priority (internal code)

Enum:
Array [ 3 ]
created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
Creation date

updated_at	string($date-time)
title: Updated at
readOnly: true
x-nullable: true
Update date


}
Notifications - Devices


POST
/notifications/devices/register/
notifications_devices_register_create

Зарегистрировать FCM-токен устройства для push-уведомлений

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"token": "string",
"device_id": "string",
"platform": "web",
"language": "en"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/notifications/devices/register/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"token": "string",
"device_id": "string",
"platform": "web",
"language": "en"
}'
Request URL
http://192.168.100.149:8000/api/v1/notifications/devices/register/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:30 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
201
Example Value
Model
Device{
id	integer
title: ID
readOnly: true
Device ID

token*	string
title: Token
minLength: 1
Device FCM token

device_id	string
title: Device id
maxLength: 255
x-nullable: true
Device identifier

platform	string
title: Platform
Device platform

Enum:
[ android, ios, web ]
language	string
title: Language
Push notification language

Enum:
Array [ 3 ]
is_active	boolean
title: Is active
readOnly: true
Whether the device is active

created_at	string($date-time)
title: Created at
readOnly: true
x-nullable: true
Registration date


}

POST
/notifications/devices/unregister/
notifications_devices_unregister_create

Отменить регистрацию FCM-токена устройства

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"token": "string"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/notifications/devices/unregister/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"token": "string"
}'
Request URL
http://192.168.100.149:8000/api/v1/notifications/devices/unregister/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:42 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
ControllerDefaultResponse{
message	string
title: Message
default: Ok
minLength: 1
result	Result{

}

}
Payment


GET
/payment/cards/
payment_cards_list

Get user cards.

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/payment/cards/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/payment/cards/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:52 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CardToken{
id*	integer
title: Id
masked_card_number*	string
title: Masked card number
minLength: 1
is_default*	boolean
title: Is default
status*	string
title: Status
minLength: 1

}

POST
/payment/cards/
payment_cards_create

Add new card.

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"card_number": "string",
"expire_date": "stri"
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/payment/cards/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"card_number": "string",
"expire_date": "stri"
}'
Request URL
http://192.168.100.149:8000/api/v1/payment/cards/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:23:58 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CardToken{
id*	integer
title: Id
masked_card_number*	string
title: Masked card number
minLength: 1
is_default*	boolean
title: Is default
status*	string
title: Status
minLength: 1

}

DELETE
/payment/cards/{card_id}/
payment_cards_delete

Delete card.

Parameters
Cancel
Name	Description
card_id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'DELETE' \
'http://192.168.100.149:8000/api/v1/payment/cards/1/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/payment/cards/1/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:08 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CardToken{
id*	integer
title: Id
masked_card_number*	string
title: Masked card number
minLength: 1
is_default*	boolean
title: Is default
status*	string
title: Status
minLength: 1

}

POST
/payment/cards/{card_id}/set-default/
payment_cards_set-default_create

Set card as default.

Parameters
Cancel
Name	Description
card_id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/payment/cards/1/set-default/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d ''
Request URL
http://192.168.100.149:8000/api/v1/payment/cards/1/set-default/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:17 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CardToken{
id*	integer
title: Id
masked_card_number*	string
title: Masked card number
minLength: 1
is_default*	boolean
title: Is default
status*	string
title: Status
minLength: 1

}

POST
/payment/cards/{card_id}/verify/
payment_cards_verify_create

Verify card with SMS code.

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"sms_code": "string"
}
Cancel
Parameter content type

application/json
card_id *
string
(path)
1
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/payment/cards/1/verify/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"sms_code": "string"
}'
Request URL
http://192.168.100.149:8000/api/v1/payment/cards/1/verify/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:25 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CardToken{
id*	integer
title: Id
masked_card_number*	string
title: Masked card number
minLength: 1
is_default*	boolean
title: Is default
status*	string
title: Status
minLength: 1

}

POST
/payment/subscriptions/purchase/
payment_subscriptions_purchase_create

Purchase selected plan.

Parameters
Cancel
Name	Description
data *
object
(body)
Edit Value
Model
{
"plan_id": 0
}
Cancel
Parameter content type

application/json
Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'POST' \
'http://192.168.100.149:8000/api/v1/payment/subscriptions/purchase/' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK' \
-d '{
"plan_id": 0
}'
Request URL
http://192.168.100.149:8000/api/v1/payment/subscriptions/purchase/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
access-control-allow-credentials: true
access-control-allow-origin: http://192.168.100.149:8000
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:33 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
PurchasePlanResponse{
message*	string
title: Message
minLength: 1
subscription_id*	integer
title: Subscription id
plan_id*	integer
title: Plan id
plan_name*	string
title: Plan name
minLength: 1
billing_period*	string
title: Billing period
minLength: 1
storage_limit*	integer
title: Storage limit
used_storage*	integer
title: Used storage
available_storage*	integer
title: Available storage
starts_at*	string($date-time)
title: Starts at
ends_at*	string($date-time)
title: Ends at
x-nullable: true

}
Subscription


GET
/storage/subscription/current/
storage_subscription_current_list

Get current subscription and storage information

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/storage/subscription/current/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/storage/subscription/current/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:40 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
CurrentSubscriptionResponse{
plan_id*	integer
title: Plan id
x-nullable: true
plan_name*	string
title: Plan name
minLength: 1
x-nullable: true
billing_period*	string
title: Billing period
minLength: 1
x-nullable: true
starts_at*	string($date-time)
title: Starts at
ends_at*	string($date-time)
title: Ends at
storage_limit*	integer
title: Storage limit
used_storage*	integer
title: Used storage
available_storage*	integer
title: Available storage

}
Storage


GET
/storage/usage/
storage_usage_list

Storage usage

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/storage/usage/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/storage/usage/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:47 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
UserStorageUsage{
percent_used*	number
title: Percent used
remaining*	number
title: Remaining
images*	number
title: Images
videos*	number
title: Videos

}

GET
/storage/used/
storage_used_list

Storage used

Parameters
Cancel
No parameters

Execute
Clear
Responses
Response content type

application/json
Curl

curl -X 'GET' \
'http://192.168.100.149:8000/api/v1/storage/used/' \
-H 'accept: application/json' \
-H 'X-CSRFTOKEN: LugQeQD9eDpflfyRFMfGEsMcdl16lKrPeQX207BMogrJx3rCOeZzw43LXDFrXEDK'
Request URL
http://192.168.100.149:8000/api/v1/storage/used/
Server response
Code	Details
401
Undocumented
Error: Unauthorized

Response body
Download
{
"message": "Authentication credentials are invalid.",
"message_key": "unauthorized"
}
Response headers
content-language: ru
content-length: 85
content-type: application/json
cross-origin-opener-policy: same-origin
date: Thu,13 Aug 2026 09:24:52 GMT
referrer-policy: same-origin
server: WSGIServer/0.2 CPython/3.12.10
vary: Accept-Language,origin
x-content-type-options: nosniff
Responses
Code	Description
200
Example Value
Model
UserStorageUsed{
storage_limit*	number
title: Storage limit
used_storage*	number
title: Used storage
percent_used*	number
title: Percent used
remaining*	number
title: Remaining

}

Models
UserDisable
UserMe
UserLogin
ControllerDefaultResponse
OTPResend
OTP
OTPResponse
UserPasswordReset
Register
RefreshToken
UserUpdate
Contact
BulkDownloadRequest
User
File
FavouriteFileList
FavouriteFileCreate
FileItem
FilesCheckDuplicate
FilesCheckDuplicateResponse
FileDownload
FilePreview
FolderFileDelete
FolderFileMove
FolderFileRename
Folder
FolderCreate
FolderDetail
InfoRequest
PinnedFolderList
PinnedFolderCreate
SelectionInfoRequest
SelectionInfo
ShareRequestPermissionCreate
ShareRequestList
ShareRequestPermissionList
ShareRequestPermissionUpdate
ShareRequestCreate
ShareRequestCheckPermission
ShareRequestCheckPermissionOwner
ShareRequestItem
ShareRequestDetail
FileShare
FileShareCreate
SharedByMeUser
SharedWithMeUser
Notification
DeviceRegister
Device
DeviceDelete
UnreadCount
CardToken
AddCardRequest
VerifyCardRequest
PurchasePlanRequest
PurchasePlanResponse
PlanItem
Plan
CurrentSubscriptionResponse
UserStorageUsage
UserStorageUsed
Online validator badge