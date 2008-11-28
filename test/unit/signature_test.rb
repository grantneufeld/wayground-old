require 'test_helper'

class SignatureTest < ActiveSupport::TestCase
	fixtures :users, :petitions, :signatures
	
	
	# ASSOCIATIONS
	
	def test_associations
		assert check_associations
		
		# belongs_to :petition
		assert_equal petitions(:one), signatures(:one).petition
		# belongs_to :user
		assert_equal users(:admin), signatures(:one).user
	end
	
	
	# ACCESSIBLE ATTRIBUTES
	
	def test_signature_set_accessible_fields
		s = Signature.new({:is_public=>true, :allow_followup=>true,
			:name=>'value', :email=>'value', :phone=>'value',
			:address=>'value', :city=>'value', :province=>'value',
			:country=>'value', :postal_code=>'value', :custom_field=>'value',
			:comment=>'value'})
		assert s.is_public
		assert s.allow_followup
		assert_equal 'value', s.name
		assert_equal 'value', s.email
		assert_equal 'value', s.phone
		assert_equal 'value', s.address
		assert_equal 'value', s.city
		assert_equal 'value', s.province
		assert_equal 'value', s.country
		assert_equal 'value', s.postal_code
		assert_equal 'value', s.custom_field
		assert_equal 'value', s.comment
	end
	def test_signature_dont_set_inaccessible_fields
		assert_raise(Wayground::AssignToProtectedAttribute) do
			s = Signature.new({
				:id=>1234,
				:position=>456,
				:petition_id=>petitions(:one).id,
				:user_id=>users(:admin).id,
				:confirmation_code=>'should not be set',
				:confirmed_at=>Time.now,
				:created_at=>Time.now,
				:updated_at=>Time.now})
		end
		#assert_nil s.id
		#assert_nil s.position
		#assert_nil s.petition_id
		#assert_nil s.user_id
		#assert_nil s.confirmation_code
		#assert_nil s.confirmed_at
		#assert_nil s.created_at
		#assert_nil s.updated_at
	end
	
	
	# VALIDATIONS
	
	#validates_presence_of :petition
	#validates_presence_of :name
	#validates_presence_of :email
	#validates_uniqueness_of :user_id, :scope=>:petition_id,
	#	:message=>'you have already signed this petition',
	#	:if=>Proc.new {|sig| !(sig.user.nil?)}
	#validates_uniqueness_of :email, :scope=>:petition_id,
	#	:message=>'invalid signature'
	
	def test_signature_valid_required_fields
		s = Signature.new({:name=>'Test', :email=>'test@wayground.ca'})
		s.petition = petitions(:one)
		assert s.valid?
	end
	def test_signature_invalid_required_fields
		s = Signature.new()
		assert !(s.valid?)
		s = Signature.new({:name=>'Test'})
		s.petition = petitions(:one)
		assert !(s.valid?)
		s = Signature.new({:email=>'test@wayground.ca'})
		s.petition = petitions(:one)
		assert !(s.valid?)
		s = Signature.new({:name=>'Test', :email=>'test@wayground.ca'})
		assert !(s.valid?)
	end
	
	
	# CLASS METHODS
	
	def test_signature_confirm
		s = Signature.confirm('confirm_confirmation_code')
		assert_equal signatures(:confirm), s
		assert s.confirmed_at > 1.minute.ago
		assert_nil s.user
		# now that it has been confirmed, should not be able to re-confirm
		assert_raise ActiveRecord::RecordNotFound do
			s = Signature.confirm('confirm_confirmation_code')
		end
	end
	def test_signature_confirm_set_user
		s = Signature.confirm('confirm_confirmation_code', users(:staff))
		assert_equal signatures(:confirm), s
		assert s.confirmed_at > 1.minute.ago
		assert_equal users(:staff), s.user
	end
	def test_signature_confirm_fail_reconfirm
		# should not be able to re-confirm already confirmed signature
		assert_raise ActiveRecord::RecordNotFound do
			s = Signature.confirm('confirmed_confirmation_code')
		end
	end
	
	def test_signature_confirm_for_user
		s = Signature.confirm('confirm_user_confirmation_code', users(:admin))
		assert_equal signatures(:confirm_user), s
		assert s.confirmed_at > 1.minute.ago
		assert_equal users(:admin), s.user
	end
	def test_signature_confirm_for_user_no_user
		assert_raise Wayground::UserMismatch do
			s = Signature.confirm('confirm_user_confirmation_code')
		end
	end
	def test_signature_confirm_for_user_wrong_user
		assert_raise Wayground::UserMismatch do
			s = Signature.confirm('confirm_user_confirmation_code', users(:login))
		end
	end
	
	def test_signature_confirm_invalid_code
		assert_raise ActiveRecord::RecordNotFound do
			s = Signature.confirm('invalid code')
		end
	end
end
