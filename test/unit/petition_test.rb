require 'test_helper'

class PetitionTest < ActiveSupport::TestCase
	fixtures :users, :petitions, :signatures
	
	# ASSOCIATIONS
	
	def test_associations
		assert check_associations
		
		# belongs_to :user
		assert_equal users(:admin), petitions(:one).user
		# has_many :signatures
		assert_equal [signatures(:one)], petitions(:one).signatures
		
	end
	
	
	# ACCESSIBLE ATTRIBUTES
	
	def test_petition_set_accessible_fields
		t = Time.now
		p = Petition.new({:subpath=>'value', :start_at=>t, :end_at=>t,
			:public_signatures=>true, :allow_comments=>true, :goal=>123,
			:title=>'value', :description=>'value', :custom_field_label=>'value',
			:country_restrict=>'value', :province_restrict=>'value',
			:city_restrict=>'value', :restriction_description=>'value',
			:content=>'value', :thanks_message=>'value'})
		assert p.public_signatures
		assert p.allow_comments
		assert_equal t, p.start_at
		assert_equal t, p.end_at
		assert_equal 123, p.goal
		assert_equal 'value', p.subpath
		assert_equal 'value', p.title
		assert_equal 'value', p.description
		assert_equal 'value', p.custom_field_label
		assert_equal 'value', p.country_restrict
		assert_equal 'value', p.province_restrict
		assert_equal 'value', p.city_restrict
		assert_equal 'value', p.restriction_description
		assert_equal 'value', p.content
		assert_equal 'value', p.thanks_message
	end
	def test_petition_dont_set_inaccessible_fields
		p = Petition.new({:id=>1234,
			:user_id=>users(:admin).id,
			:created_at=>Time.now,
			:updated_at=>Time.now})
		assert_nil p.id
		assert_nil p.user_id
		assert_nil p.created_at
		assert_nil p.updated_at
	end
	
	
	# VALIDATIONS
	
	#validates_presence_of :subpath
	#validates_presence_of :user
	#validates_presence_of :title
	#validates_presence_of :content
	#validates_exclusion_of :subpath, :in=>WAYGROUND['RESERVED_SUBPATHS'],
	#	:message=>"the subpath %s is reserved and cannot be used for your petition"
	#validates_format_of :subpath,
	#	:with=>/\A[A-Za-z][\w\-]*\z/,
	#	:message=>'must begin with a letter and only consist of letters, numbers and/or dashes (a-z, 0-9, -)'
	#validates_uniqueness_of :subpath,
	#	:message=>'that subpath is already in use by another petition'
	#validates_uniqueness_of :title,
	#	:message=>'that title is already in use by another petition'
	
	def test_petition_valid_required_fields
		p = Petition.new({:subpath=>'valid', :title=>'Validation Test',
			:content=>'This should be a valid petition.'})
		p.user = users(:admin)
		assert p.valid?
	end
	def test_petition_invalid_required_fields
		p = Petition.new()
		assert !(p.valid?)
		p = Petition.new({:subpath=>'valid', :title=>'Validation Test'})
		p.user = users(:admin)
		assert !(p.valid?)
		p = Petition.new({:subpath=>'valid',
			:content=>'This should be a valid petition.'})
		p.user = users(:admin)
		assert !(p.valid?)
		p = Petition.new({:title=>'Validation Test',
			:content=>'This should be a valid petition.'})
		p.user = users(:admin)
		assert !(p.valid?)
		p = Petition.new({:subpath=>'valid', :title=>'Validation Test',
			:content=>'This should be a valid petition.'})
		assert !(p.valid?)
	end
end
