class User < ActiveRecord::Base
  include BCrypt
  include Scrubber
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation
  serialize :omniauth_data, JSON
  #Scrubber Fields
  before_save :create_unique_profile_id
  before_save :create_beamer_id
  
  #Authentications
  validate do |user|
    if user.new_record? #adds validation if it is a new record
      user.errors.add(:first_name, "First Name Field cannot be blank") if user.first_name.blank?
      user.errors.add(:last_name, "Last Name Field cannot be blank") if user.last_name.blank?
      user.errors.add(:password, "is required") if user.password.blank?
      user.errors.add(:password_confirmation, "is required") if user.password_confirmation.blank?
      user.errors.add(:password, "Password and confirmation must match") if user.password != user.password_confirmation
    elsif !(!user.new_record? && user.password.blank? && user.password_confirmation.blank?) #adds validation only if password or password_confirmation are modified
      user.errors.add(:first_name, "First Name Field cannot be blank") if user.first_name.blank?
      user.errors.add(:first_name, "Last Name Field cannot be blank") if user.last_name.blank?
      user.errors.add(:password, "is required") if user.password.blank?
      user.errors.add(:password_confirmation, "is required") if user.password_confirmation.blank?
      user.errors.add(:password, " and confirmation must match.") if user.password != user.password_confirmation
      user.errors.add(:password, " and confirmation should be atleast 4 characters long.") if user.password.length < 4 || user.password_confirmation.length < 4
    end
  end
  #For OmniAuth
  has_many :authorizations, :dependent => :destroy

  #For Authlogic
  acts_as_authentic do |c|
    c.ignore_blank_passwords = true #ignoring passwords
    c.validate_password_field = false #ignoring validations for password fields
  end

  #Messages
  has_many :sent_messages,
  :class_name => 'Message',
  :primary_key=>'beamer_id',
  :foreign_key => 'sender_id',
  :order => "messages.created_at DESC",
  :conditions => ["messages.sender_deleted = ?", false]

  has_many :received_messages,
  :class_name => 'Message',
  :primary_key=>'beamer_id',
  :foreign_key => 'recepient_id',
  :order => "messages.created_at DESC",
  :conditions => ["messages.recepient_deleted = ?", false]

  # friendships
  has_many :friendship,:primary_key=>"beamer_id",:foreign_key=>'beamer_id'
  has_many :friends, 
           :through => :friendship,
           :conditions => "status = 'accepted'", 
           :order => :first_name

  has_many :requested_friends, 
           :through => :friendship, 
           :source => :friend,
           :conditions => "status = 'requested'", 
           :order => :created_at

  has_many :pending_friends, 
           :through => :friendship, 
           :source => :friend,
           :conditions => "status = 'pending'", 
           :order => :created_at

  def self.create_from_omniauth_data(omniauth_data)
    user = User.new(
      :first_name => omniauth_data['info']['name'].to_s.downcase,
      :email => omniauth_data['info']['email'].to_s.downcase#if present
      )
    user.omniauth_data = omniauth_data.to_json #shove OmniAuth::AuthHash as json data to be parsed later!
    user.save(:validate => false) #create without validations because most of the fields are not set.
    user.reset_persistence_token! #set persistence_token else sessions will not be created
    user
  end

  def create_beamer_id
    self.beamer_id=gen_beamer_id
  end

  def create_unique_profile_id
    self.profile_id=gen_profile_id
  end

  def full_name
    return "#{self.first_name} #{self.last_name}"
  end

  def unread_messages?
    unread_message_count > 0 ? true : false
  end

  # Returns the number of unread messages for this user
  def unread_message_count
    eval 'messages.count(:conditions => ["recepient_id = ? AND read_at IS NULL", self.beamer_id])'
  end
end
