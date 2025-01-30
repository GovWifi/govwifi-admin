module EmailHelpers
  def it_sent_one_email
    expect(Services.notify_gateway.count_all_emails).to eq(1)
  end

  def it_sent_an_email_to(address)
    expect(Services.notify_gateway.last_email_address).to eq(address)
  end

  def it_sent_a_confirmation_email
    expect(email_count("confirmation_email_template")).to eq(1)
  end

  def it_sent_a_confirmation_email_twice
    expect(email_count("confirmation_email_template")).to eq(2)
  end

  def it_did_not_send_a_confirmation_email
    expect(email_count("confirmation_email_template")).to eq(0)
  end

  def it_sent_an_invitation_email_once
    expect(email_count("invite_email_template")).to eq(1)
  end

  def it_sent_an_invitation_email_twice
    expect(email_count("invite_email_template")).to eq(2)
  end

  def it_did_not_send_an_invitation_email
    expect(email_count("invite_email_template")).to eq(0)
  end

  def it_sent_a_cross_organisational_invitation_email
    expect(email_count("cross_organisation_invitation_template")).to eq(1)
  end

  def it_did_not_send_a_cross_organisational_invitation_email
    expect(email_count("cross_organisation_invitation_template")).to eq(0)
  end

  def it_did_not_send_any_emails
    expect(Services.notify_gateway.count_all_emails).to eq(0)
  end

  def it_sent_a_nomination_email_once
    expect(email_count("nominate_user_to_sign_mou_template")).to eq(1)
  end

  def it_sent_a_thank_you_for_signing_the_mou_email_once
    expect(email_count("thank_you_for_signing_the_mou_template")).to eq(1)
  end

  def it_sent_a_notify_user_email_once
    expect(email_count("user_account_removed_email_template")).to eq(1)
  end

  def email_count(template_name)
    Services.notify_gateway.count_emails_with_template template_name
  end
end
