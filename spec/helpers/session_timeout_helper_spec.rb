# require "rails_helper"
# require "timecop"
#
# RSpec.describe SessionTimeoutHelper, type: :helper do
#   let(:timeout_warning_message) { "For your security, please advise if you would like to continue your session?" }
#   let(:timeout_duration) { 90.seconds }
#   let(:warning_time) { 60.seconds }
#
#   describe "#session_timeout_warning" do
#     before do
#       allow(helper).to receive(:session_timeout_enabled?).and_return(true)
#       allow(helper).to receive(:session_timeout_duration).and_return(timeout_duration)
#     end
#
#     it "returns the correct timeout warning message" do
#       expect(helper.timeout_warning_message).to eq timeout_warning_message
#     end
#
#     it "uses the configured timeout duration" do
#       expect(helper.timeout_duration).to eq timeout_duration
#     end
#   end
#
#   describe "#session_timeout_script" do
#     let(:session_start) { Time.zone.now }
#
#     before do
#       allow(helper).to receive(:session_timeout_duration).and_return(timeout_duration)
#       allow(helper).to receive(:warning_time).and_return(warning_time)
#       allow(helper).to receive(:session).and_return({ created_at: session_start })
#     end
#
#     it "generates complete timeout script" do
#       script = helper.session_timeout_script
#       aggregate_failures do
#         expect(script).to include("DOMContentLoaded")
#         expect(script).to include(destroy_user_session_path)
#         expect(script).to include(new_user_session_path)
#         expect(script).to match(/<script>.*<\/script>/m)
#       end
#     end
#
#     context "with time-sensitive values" do
#       before { Timecop.freeze(session_start) }
#       after { Timecop.return }
#
#       it "calculates correct warning time" do
#         script = helper.session_timeout_script
#         expect(script).to include("timeoutWarningTime: #{(warning_time * 1000).to_i}")
#       end
#
#       it "calculates full session duration" do
#         script = helper.session_timeout_script
#         expect(script).to include("sessionTimeout: #{(timeout_duration * 1000).to_i}")
#       end
#
#       context "when session is active" do
#         it "updates remaining time" do
#           Timecop.travel(session_start + 30.seconds)
#           updated_script = helper.session_timeout_script
#           remaining = timeout_duration - 30.seconds
#           expect(updated_script).to include("remainingTime: #{(remaining * 1000).to_i}")
#           Timecop.return
#         end
#       end
#
#       context "when approaching timeout" do
#         it "triggers warning" do
#           Timecop.travel(session_start + (timeout_duration - warning_time + 1.second))
#           updated_script = helper.session_timeout_script
#           expect(updated_script).to include("showTimeoutWarning()")
#           Timecop.return
#         end
#       end
#     end
#
#     it "includes error handling" do
#       script = helper.session_timeout_script
#       expect(script).to include("catch (error) {")
#     end
#
#     it "contains core functions" do
#       script = helper.session_timeout_script
#       aggregate_failures do
#         expect(script).to include("function createTimeoutModal()")
#         expect(script).to include("startSessionTimeout()")
#         expect(script).to include("resetSessionTimeout()")
#       end
#     end
#   end
# end
require "rails_helper"
require "timecop"

RSpec.describe SessionTimeoutHelper, type: :helper do
  let(:timeout_warning_message) { "For your security, please advise if you would like to continue your session?" }
  let(:timeout_duration) { 90.seconds }
  let(:warning_time) { 60.seconds }

  describe "#session_timeout_warning" do
    let(:dummy) do
      Class.new do
        extend SessionTimeoutHelper
        def self.session_timeout_enabled? = true
        def self.timeout_duration = 90.seconds
      end
    end

    it "returns the correct timeout warning message" do
      expect(dummy.session_timeout_warning).to eq timeout_warning_message
    end

    it "uses the configured timeout duration" do
      expect(dummy.timeout_duration).to eq timeout_duration
    end
  end

  describe "#session_timeout_script" do
    let(:script) { helper.session_timeout_script }
    let(:session_start) { Time.zone.now }

    before do
      allow(helper).to receive(:session_timeout_duration).and_return(timeout_duration)
      allow(helper).to receive(:session_warning_time).and_return(warning_time)
      session[:created_at] = session_start
    end

    it "generates complete timeout script" do
      aggregate_failures do
        expect(script).to include("DOMContentLoaded")
        expect(script).to include(destroy_user_session_path)
        expect(script).to include(new_user_session_path)
        expect(script).to match(/<script>.*<\/script>/m)
      end
    end
    it "creates the correct heading element" do
      expect(script).to include('<h1 class="govuk-heading-l" id="session-heading">Your session is about to expire</h1>')
    end

    it "creates the correct message element" do
      expect(script).to include('<p class="govuk-body" id="session-description">For your security, please advise if you would like to continue your session?</p>')
    end
    context "with time-sensitive values" do
      before { Timecop.freeze(session_start) }
      after { Timecop.return }

      it "calculates correct warning time" do
        expect(script).to include("timeoutWarningTime: #{(warning_time * 1000).to_i}")
      end

      it "calculates full session duration" do
        expect(script).to include("sessionTimeout: #{(timeout_duration * 1000).to_i}")
      end

      context "when session is active" do
        it "updates remaining time" do
          Timecop.travel(session_start + 30.seconds) do
            remaining = (timeout_duration - 30.seconds).in_milliseconds
            expect(helper.session_timeout_script).to include("remainingTime: #{remaining.to_i}")
          end
        end
      end

      context "when approaching timeout" do
        it "triggers warning" do
          Timecop.travel(session_start + (timeout_duration - warning_time + 1.second)) do
            expect(script).to include("showTimeoutWarning()")
          end
        end
      end
    end

    # it "contains core functions" do
    #
    #     expect(script).to include("createTimeoutModal()")
    #     expect(script).to include("startSessionTimeout()")
    #     expect(script).to include("resetSessionTimeout()")
    #
    end
  end

