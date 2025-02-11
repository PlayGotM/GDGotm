class_name GotmAuth


## A GotmAuth gives permission to do things on behalf of a user.
##
## A global GotmAuth instance is always active and is used by this
## plugin behind the scenes. You can retrieve the global GotmAuth
## instance by calling [code]await GotmAuth.fetch()[/code].
## [codeblock]
## func is_user_signed_in() -> bool:
##     var gotm_authentification: GotmAuth = await GotmAuth.fetch()
##     return gotm_authentification.is_registered
## [/codeblock]
## [br]
## If the user has signed in, the global GotmAuth instance represents
## that user. If the user has not signed in, the global GotmAuth
## instance represents an unregistered anonymous user (a guest).

##############################################################
# PROPERTIES
##############################################################

## Unique identifier of the user whom the authentication represents.
var user_id: String

## Is true if the user has a registered account.
## Some functions in this plugin requires that the current user
## is registered, for example GotmMark.create.
var is_registered: bool

##############################################################
# METHODS
##############################################################

## Get the currently active authentication.
## If the user is not signed in, the returned GotmAuth
## will represent an unregistered anonymous user (a guest).
static func fetch() -> GotmAuth:
	return await _GotmAuth.fetch()

##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "GotmAuth"