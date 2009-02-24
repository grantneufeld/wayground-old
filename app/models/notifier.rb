module Wayground
	# Failed to send the notification.
	class NotifierSendFailure < Exception; end
end

# email notification delivery
# ¶¶¶ testing to avoid mailer problems
#class Notifier < ActionMailer::ARMailer
class Notifier < ActionMailer::Base
	# sent when a new user registers
	def signup_confirmation(email_address, sent_at = Time.current)
		setup_email_for_email_address(email_address, sent_at)
		@subject += 'Please activate your new account'
		@body[:url] = "#{WAYGROUND['ROOT']}/activate/#{email_address.activation_code}/#{email_address.encrypt_code}"
	end
	
	# sent when a user has confirmed their email address
	def activated(email_address, sent_at = Time.current)
		setup_email_for_email_address(email_address, sent_at)
		@subject += 'Your account has been activated'
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
	
	# options:hash:
	# - :recipient - Recipient
	# - :from - string
	# - :reply_to - string
	# - :subject - string
	# - :content - string
	# - :sent_at - datetime
	def email_message(options={})
		#recipients = '', from = Wayground::SENDER, reply_to = '', subject = '', content = '', sent_at = Time.now
		
		@subject = options[:subject]
		@body = {"content"=>options[:content]}
		# Email body substitutions go here
		#@body["first_name"] = user.first_name
		#@body["last_name"] = user.last_name
		
		@recipients = options[:recipient].to_s
		@from = options[:from]
		@sent_on = options[:sent_at]
		@headers = {}
		unless @from.match("^(.*<)?#{WAYGROUND['EMAIL_BOUNCE']}>?$")
			# sender is not the same as the email bounce address
			unless Site.is_local_email?(@from)
				# not a local email address,
				# so identify the source as the email bounce address
				#@headers['Envelope-From'] = "<#{WAYGROUND['EMAIL_BOUNCE']}>"
				@headers['Return-Path'] = "<#{WAYGROUND['EMAIL_BOUNCE']}>"
				@headers['Sender'] = WAYGROUND['EMAIL_BOUNCE']
			end
			# direct bounces to the email bounce address
			@headers['Errors-To'] = WAYGROUND['EMAIL_BOUNCE']
		end
		unless options[:reply_to].blank?
			@headers["Reply-To"] = options[:reply_to]
		end
	end
	
	
	protected
	
	# common setup for outgoing emails without a user
	def setup_email(email, fullname, sent_at = Time.current)
		@subject = "[#{WAYGROUND['TITLE_SHORT']}] "
		@body = {}
		@recipients = (fullname.blank? ? "#{email}" :
			"\"#{fullname}\" <#{email}>")
		@from = WAYGROUND['SENDER']
		@sent_on = sent_at
		@headers = {}
	end
	
	# common setup for outgoing emails for an EmailAddress
	def setup_email_for_email_address(e, sent_at = Time.current)
		setup_email(e.email, e.name, sent_at)
		@body[:email_address] = e
	end
	
end
