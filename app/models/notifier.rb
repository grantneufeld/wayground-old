# email notification delivery
class Notifier < ActionMailer::ARMailer

	# sent when a new user registers
	def signup_confirmation(user, sent_at = Time.current)
		setup_email(user, sent_at)
		@subject += 'Please activate your new account'
		@body[:url] = "#{WAYGROUND['ROOT']}/activate/#{user.activation_code}"
	end
	
	# sent when a user has confirmed their email address
	def activated(user, sent_at = Time.current)
		setup_email(user, sent_at)
		@subject += 'Your account has been activated!'
		@body[:url] = "#{WAYGROUND['ROOT']}/"
	end
	
	
	protected
	
	# common setup for all outing emails
	def setup_email(user, sent_at)
		@subject = "[#{WAYGROUND['TITLE_SHORT']}] "
		@body = {}
		@body[:user] = user
		@recipients = (user.fullname.blank? ? "#{user.email}" :
			"\"#{user.fullname}\" <#{user.email}>")
		@from = WAYGROUND['SENDER']
		@sent_on = sent_at
		@headers = {}
	end
end
