# Security fix
# There is a bug in all 2.1.x versions of Ruby on Rails which affects
# the effectiveness of the CSRF protection given by
# protect_from_forgery.

# This file is only needed for Rails versions < 2.1.3

Mime::Type.unverifiable_types.delete(:text)