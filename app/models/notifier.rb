module Wayground
	# Failed to send the notification.
	class NotifierSendFailure < Exception; end
end

# email notification delivery
# ¶¶¶ testing to avoid mailer problems
#class Notifier < ActionMailer::ARMailer
class Notifier < ActionMailer::Base
	# sent when a new user registers
	def signup_confirmation(user, sent_at = Time.current)
		setup_email_for_user(user, sent_at)
		@subject += 'Please activate your new account'
		@body[:url] = "#{WAYGROUND['ROOT']}/activate/#{user.activation_code}"
	end
	
	# sent when a user has confirmed their email address
	def activated(user, sent_at = Time.current)
		setup_email_for_user(user, sent_at)
		@subject += 'Your account has been activated!'
		@body[:url] = "#{WAYGROUND['ROOT']}/"
	end
	
	# sent when a Signature is added to a Petition
	def signature_confirmation(petition, signature, user=nil, sent_at = Time.current)
		setup_email(signature.email, signature.name, sent_at)
		@subject += "Petition signature confirmation: #{petition.title}"
		@body[:petition] = petition
		@body[:signature] = signature
		@body[:url] = "#{WAYGROUND['ROOT']}/petitions/#{petition.id}/signatures/#{signature.id}/confirm?code=#{signature.confirmation_code}"
		#confirm_petition_signature_url(petition, signature, :code=>signature.confirmation_code)
	end
	
	
	protected
	
	# common setup for outgoing emails without a user
	def setup_email(email, fullname, sent_at)
		@subject = "[#{WAYGROUND['TITLE_SHORT']}] "
		@body = {}
		@body[:user] = nil
		@recipients = (fullname.blank? ? "#{email}" :
			"\"#{fullname}\" <#{email}>")
		@from = WAYGROUND['SENDER']
		@sent_on = sent_at
		@headers = {}
	end
	
	# common setup for outgoing emails for a user
	def setup_email_for_user(user, sent_at)
		setup_email(user.email, user.fullname, sent_at)
		@body[:user] = user
	end
	
end
