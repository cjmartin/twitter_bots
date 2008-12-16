require 'rubygems'
require 'active_record'
require 'twitter'
require 'cgi'

# twitter account to use
twitter_id    = "twitter_id_to_post_to"
twitter_pass  = "sekrit_password"

# sqlite db, it will be created on first run if it doesn't exist
path_to_sqlite_db = "PATH/TO/your_db.sqlite"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :dbfile  => path_to_sqlite_db
)

# uncomment this section the first time to create the table
#ActiveRecord::Schema.define do
#  create_table :msgs do |table|
#    table.column :body, :string
#  end
#end

class Msg < ActiveRecord::Base
  # use to_s before sending messages back to twitter 
  def to_s
    CGI::unescapeHTML(self.body)
  end
end

twitter = Twitter::Base.new(twitter_id, twitter_pass)

twitter.direct_messages.each do |msg|
  Msg.transaction do
    # unless the DM is in the database, add it and re-post as a status message
    unless existing_msg = Msg.find(:all, :conditions => ["body=?", msg.text]).first
      new_msg = Msg.create(:body => msg.text)
      # you may want to comment out twitter.post on first run if there are existing DMs you don't want to re-post
      twitter.post(new_msg.to_s)
    end
  end
end
