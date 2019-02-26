describe 'Authorised Email Domains' do
  context 'when logged in' do
    before do
      sign_in_user admin_user
      visit new_admin_authorised_email_domain_path
    end

    context 'as super admin' do
      let(:admin_user) { create(:user, super_admin: true) }

      context 'given I want to whitelist a domain' do
        before do
          fill_in 'Name', with: some_domain
        end

        context 'adding a new domain' do
          let(:some_domain) { 'gov.uk' }

          it 'authorise a new domain' do
            expect { click_on 'Save' }.to change { AuthorisedEmailDomain.count }.by(1)
            expect(page).to have_content("#{some_domain} authorised")
          end

          it 'publishes the authorised domains to S3' do
            expect_any_instance_of(Gateways::S3).to receive(:write).with(data: SIGNUP_WHITELIST_PREFIX_MATCHER + '(gov\.uk)$')
            click_on 'Save'
          end
        end

        context 'Submitting a blank domain' do
          let(:some_domain) { '' }

          it 'renders an error' do
            expect { click_on 'Save' }.to_not(change { AuthorisedEmailDomain.count })
            expect(page).to have_content("Name can't be blank")
          end
        end

        context 'deleting a whitelisted domain' do
          let(:some_domain) { 'police.uk' }

          it 'removes a domain' do
            click_on 'Save'
            click_on 'Remove'

            expect { click_on 'Yes, remove this email domain' }.to change { AuthorisedEmailDomain.count }.by(-1)
            expect(page).to have_content("#{some_domain} has been deleted")
          end

          it 'publishes an updated list of authorised domains to S3' do
            click_on 'Save'
            click_on 'Remove'

            expect_any_instance_of(Gateways::S3).to receive(:write).with(data: '^$')
            click_on 'Yes, remove this email domain'
          end
        end
      end

      context 'viewing a list of domains' do
        it 'displays a list of domains' do
          create(:authorised_email_domain, name: 'gov.some.test.uk')
          visit admin_authorised_email_domains_path

          expect(page).to have_content('gov.some.test.uk')
        end
      end
    end

    context 'as a normal administrator' do
      let(:admin_user) { create(:user, super_admin: false) }

      it 'will redirect to root if users type address manually' do
        sign_in_user admin_user
        visit new_admin_authorised_email_domain_path

        expect(page.current_path).to eq(setup_instructions_path)
      end
    end
  end

  context 'when logged out' do
    before { visit new_admin_authorised_email_domain_path }

    it_behaves_like 'not signed in'
  end
end
