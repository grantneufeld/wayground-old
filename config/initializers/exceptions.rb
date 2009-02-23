module Wayground
	# an expected object is missing
	class NilObject < Exception; end
	# it looks like an automated form submission has been received
	class SpammerDetected < Exception; end
	# an activation code was passed that did not match
	class ActivationCodeMismatch < Exception; end
	# activation attempt when already activated
	class CannotBeActivated < Exception; end
	# failed to send an email message
	class DeliveryFailure < Exception; end
end
