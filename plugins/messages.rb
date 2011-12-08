Basil::Plugin.respond_to(/^tell ([^:]*): (.+)/) {

  to   = @match_data[1]
  from = @msg.from_name
  msg  = @match_data[2]

  Basil::Storage.with_storage do |store|
    store[:tell_messages] ||= []
    store[:tell_messages] << { :to => to, :from => from, :message => msg }
  end

  replies "Consider it noted."

}.description = "Leave a message for something"

Basil::Plugin.respond_to(/^(do i have any |any )?messages\??$/i) {

  Basil::Storage.with_storage do |store|
    msgs = store[:tell_messages].select { |msg| @msg.from_name =~ /#{msg[:to]}/i }

    if msgs.empty?
      replies "Sorry, I have no messages for you."
    else
      replies do |out|
        msgs.each do |msg|
          out << "#{msg[:from]} left you \"#{msg[:message]}\""

          # remove the message
          store[:tell_messages].delete(msg)
        end
      end
    end
  end

}.description = "See if anyone's left you a message"

Basil::Plugin.watch_for(/.*/) {

  msgs = Basil::Storage.with_storage do |store|
    store[:tell_messages].select { |msg| @msg.from_name =~ /#{msg[:to]}/i }
  end

  if !msgs.nil? && !msgs.empty?
    len = msgs.length

    # plularize correctly
    reply = if len == 1
              "You have #{len} message, say 'messages?' to me to see it."
            else
              "You have #{len} messages, say 'messages?' to me to see them."
            end

    replies reply
  else
    nil
  end

}