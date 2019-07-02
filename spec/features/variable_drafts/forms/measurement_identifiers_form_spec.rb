describe 'Measurement Identifiers Form', js: true do
  before do
    login
  end

  context 'When viewing the form with no stored values' do
    before do
      draft = create(:empty_variable_draft, user: User.where(urs_uid: 'testuser').first)
      visit edit_variable_draft_path(draft, 'measurement_identifiers')
    end

    it 'displays the correct title and description' do
      expect(page).to have_content('Measurement Identifiers')
      expect(page).to have_content('The measurement information of a variable.')
    end

    it 'has no required fields' do
      expect(page).not_to have_selector('label.eui-required-o')
    end

    context 'When clicking `Previous` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Previous'
        end
      end

      it 'saves the draft and loads the previous form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('Size Estimation')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end
      end
    end

    context 'When clicking `Next` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Next'
        end
      end

      it 'saves the draft and loads the next form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('c')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end
      end
    end

    context 'When clicking `Save` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Save'
        end
      end

      it 'saves the draft and loads the next form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('Measurement Identifiers')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('measurement_identifiers')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('measurement_identifiers')
        end
      end
    end

    context 'When selecting the previous form from the navigation dropdown' do
      before do
        within '.nav-top' do
          select 'Size Estimation', from: 'Save & Jump To:'
        end
      end

      it 'saves the draft and loads the previous form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.eui-breadcrumbs' do
          expect(page).to have_content('Variable Drafts')
          expect(page).to have_content('Size Estimation')
        end

        within '.umm-form' do
          expect(page).to have_content('Size Estimation')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end
      end
    end

    context 'When selecting the next form from the navigation dropdown' do
      before do
        within '.nav-top' do
          select 'Sampling Identifiers', from: 'Save & Jump To:'
        end
      end

      it 'saves the draft and loads the next form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.eui-breadcrumbs' do
          expect(page).to have_content('Variable Drafts')
          expect(page).to have_content('Sampling Identifiers')
        end

        within '.umm-form' do
          expect(page).to have_content('Sampling Identifiers')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end
      end
    end
  end

  context 'When viewing the form with stored values' do
    let(:draft) {
      create(:full_variable_draft, user: User.where(urs_uid: 'testuser').first)
    }

    before do
      visit edit_variable_draft_path(draft, 'measurement_identifiers')
    end

    it 'displays the correct values in the form' do
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_0_measurement_name_measurement_object', with: 'Standard Pressure')
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_0_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
      expect(page).to have_select('variable_draft_draft_measurement_identifiers_0_measurement_source', selected: 'BODC')
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_1_measurement_name_measurement_object', with: 'Entropy')
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_1_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
      expect(page).to have_select('variable_draft_draft_measurement_identifiers_1_measurement_source', selected: 'CF')
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_2_measurement_name_measurement_object', with: 'Standard Temperature')
      expect(page).to have_field('variable_draft_draft_measurement_identifiers_2_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
      expect(page).to have_select('variable_draft_draft_measurement_identifiers_2_measurement_source', selected: 'CSDMS')
    end

    context 'When clicking `Previous` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Previous'
        end
      end

      it 'saves the draft and loads the previous form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('Size Estimation')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('size_estimation')
        end
      end
    end

    context 'When clicking `Next` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Next'
        end
      end

      it 'saves the draft and loads the next form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('Sampling Identifiers')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('sampling_identifiers')
        end
      end
    end

    context 'When clicking `Save` without making any changes' do
      before do
        within '.nav-top' do
          click_button 'Save'
        end
      end

      it 'saves the draft without making any changes' do
        expect(draft.draft).to eq(Draft.last.draft)
      end

      it 'saves the draft and loads the next form' do
        within '.eui-banner--success' do
          expect(page).to have_content('Variable Draft Updated Successfully!')
        end

        within '.umm-form' do
          expect(page).to have_content('Measurement Identifiers')
        end

        within '.nav-top' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('measurement_identifiers')
        end

        within '.nav-bottom' do
          expect(find(:css, 'select[name=jump_to_section]').value).to eq('measurement_identifiers')
        end
      end

      it 'displays the correct values in the form' do
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_0_measurement_name_measurement_object', with: 'Standard Pressure')
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_0_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
        expect(page).to have_select('variable_draft_draft_measurement_identifiers_0_measurement_source', selected: 'BODC')
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_1_measurement_name_measurement_object', with: 'Entropy')
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_1_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
        expect(page).to have_select('variable_draft_draft_measurement_identifiers_1_measurement_source', selected: 'CF')
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_2_measurement_name_measurement_object', with: 'Standard Temperature')
        expect(page).to have_field('variable_draft_draft_measurement_identifiers_2_measurement_name_measurement_quantity', with: 'At Top Of Atmosphere')
        expect(page).to have_select('variable_draft_draft_measurement_identifiers_2_measurement_source', selected: 'CSDMS')
      end
    end
  end
end
