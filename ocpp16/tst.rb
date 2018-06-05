require "json-schema"
=begin

=end

module JSON
  class Schema
    class DateTimeV4Format < FormatAttribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return unless data.is_a?(String)
        DateTime.rfc3339(data)
      rescue ArgumentError
        error_message = "The property '#{build_fragment(fragments)}'='#{data}' must be a valid RFC3339 date/time string"
        validation_error(processor, error_message, fragments, current_schema, self, options[:record_errors])
      end
    end
  end
end
print"StopTransaction "
mess={idTag: "eee",meterStop: 222, timestamp: "2018-01-01T22:22:22Z",transactionId: 22,reason: "UnlockCommand"}
p JSON::Validator.validate("schemas/StopTransaction.json", mess)

print"StopTransaction "
mess={chargePointVendor: "rr", chargePointModel:"ee",chargePointSerialNumber: "rr",firmwareVersion: "1.1.1", imsi: "22343434"}
p JSON::Validator.validate("schemas/BootNotification.json", mess)


print"BootNotificationResponse "
mess={status: "Accepted", currentTime: "2018-01-01T22:22:22Z",interval: 600}
p JSON::Validator.validate("schemas/BootNotificationResponse.json", mess)

print"BootNotificationResponse "
mess={status: "Accepted", currentTime: "2018-01-01T22:22:22.001+01:01",interval: 600}
p JSON::Validator.validate!("schemas/BootNotificationResponse.json", mess,:validate_schema => true) rescue puts " ERROR : #{$!}"

print"BootNotificationResponse "
mess={status: "Accepted", currentTime: "2018-01-01T22:22:22.001Z",interval: 600}
p JSON::Validator.validate!("schemas/BootNotificationResponse.json", mess,:validate_schema => true) rescue puts " ERROR : #{$!}"
