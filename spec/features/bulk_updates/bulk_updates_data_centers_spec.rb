require 'rails_helper'

describe 'Bulk updating Data Centers' do
  before :all do
    _ingest_response, @find_and_remove_concept_response = publish_collection_draft
    @find_and_update_ingest_response_1, @find_and_update_concept_response_1 = publish_collection_draft
    @find_and_update_ingest_response_2, @find_and_update_concept_response_2 = publish_collection_draft
  end

  before do
    login

    visit new_bulk_updates_search_path
  end

  context 'when previewing a Find & Remove bulk update', js: true do
    before do
      # Search form
      select 'Entry Title', from: 'Search Field'
      find(:css, "input[id$='query_text']").set(@find_and_remove_concept_response.body['EntryTitle'])
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      select 'Data Centers', from: 'Field to Update'
      select 'Find & Remove', from: 'Update Type'
      fill_in 'Short Name', with: 'ESA/ED'
      click_on 'Preview'
    end

    it 'displays the preview information' do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Data Centers')
      expect(page).to have_content('Update Type Find And Remove')
      within '.find-values-preview' do
        expect(page).to have_content('Short Name: ESA/ED')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@find_and_remove_concept_response.body['EntryTitle'])
        expect(page).to have_content(@find_and_remove_concept_response.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page' do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Data Centers')
          expect(page).to have_content('Update Type Find And Remove')
        end

        within '.find-values-preview' do
          expect(page).to have_content('Find Values to Remove')
          expect(page).to have_content('Short Name: ESA/ED')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          within '#bulk-update-status-table' do
            click_on @find_and_remove_concept_response.body['EntryTitle']
          end
        end

        it 'no longer has the removed data center' do
          within '.data-centers-cards' do
            expect(page).to have_no_content('ESA/ED')
          end
        end
      end
    end
  end

  context 'when using Find & Update for a data center that has a Related URL', js: true do
    before(:each, bulk_update_step_1: true) do
      # Search form
      select 'Entry Title', from: 'Search Field'
      find(:css, "input[id$='query_text']").set(@find_and_update_concept_response_1.body['EntryTitle'])
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      # Update AARHUS-HYDRO to OR-STATE/EOARC
      select 'Data Centers', from: 'Field to Update'
      select 'Find & Update', from: 'Update Type'
      fill_in 'Short Name', with: 'AARHUS-HYDRO'
      # Select new Short Name from Select2
      find('.select2-container .select2-selection').click
      find(:xpath, '//body').find('.select2-dropdown li.select2-results__option', text: 'OR-STATE/EOARC').click

      click_on 'Preview'
    end

    it 'displays the preview information', bulk_update_step_1: true do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Data Centers')
      expect(page).to have_content('Update Type Find And Update')
      # Find Values to Update
      within '.find-values-preview' do
        expect(page).to have_content('Short Name: AARHUS-HYDRO')
      end

      # New Values
      within '.new-values-preview' do
        expect(page).to have_content('Short Name: OR-STATE/EOARC')
        expect(page).to have_content('Long Name: Eastern Oregon Agriculture Research Center, Oregon State University')
        expect(page).to have_content('Related Url Content Type: DataCenterURL')
        expect(page).to have_content('Related Url Type: HOME PAGE')
        expect(page).to have_content('Related URL: http://oregonstate.edu/dept/eoarcunion/')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@find_and_update_concept_response_1.body['EntryTitle'])
        expect(page).to have_content(@find_and_update_concept_response_1.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before(:each, bulk_update_step_2: true) do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page', bulk_update_step_1: true, bulk_update_step_2: true do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Data Centers')
          expect(page).to have_content('Update Type Find And Update')
        end

        within '.find-values-preview' do
          expect(page).to have_content('Find Values to Update')
          expect(page).to have_content('Short Name: AARHUS-HYDRO')
        end

        within '.new-values-preview' do
          expect(page).to have_content('New Value')
          expect(page).to have_content('Short Name: OR-STATE/EOARC')
          expect(page).to have_content('Long Name: Eastern Oregon Agriculture Research Center, Oregon State University')
          expect(page).to have_content('Related Url Content Type: DataCenterURL')
          expect(page).to have_content('Related Url Type: HOME PAGE')
          expect(page).to have_content('Related URL: http://oregonstate.edu/dept/eoarcunion/')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          visit collection_path(@find_and_update_ingest_response_1['concept-id'])
        end

        it 'displays the updated data center' do
          within '.data-centers-cards' do
            expect(page).to have_no_content('AARHUS-HYDRO')

            expect(page).to have_content('OR-STATE/EOARC')
            expect(page).to have_content('Eastern Oregon Agriculture Research Center, Oregon State University')
            # for some reason, cannot test for the 'invisible' url, because it is on '.card-body'[3], even though this can be tested for collection drafts preview
          end
        end
      end
    end
  end

  context 'when using Find & Update for a data center that does not have a Related URL', js: true do
    before(:each, bulk_update_step_1: true) do
      # Search form
      select 'Entry Title', from: 'Search Field'
      find(:css, "input[id$='query_text']").set(@find_and_update_concept_response_2.body['EntryTitle'])
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      # Update ESA/ED to AARHUS-HYDRO
      select 'Data Centers', from: 'Field to Update'
      select 'Find & Update', from: 'Update Type'
      fill_in 'Short Name', with: 'ESA/ED'
      # Select new Short Name from Select2
      find('.select2-container .select2-selection').click
      find(:xpath, '//body').find('.select2-dropdown li.select2-results__option', text: 'AARHUS-HYDRO').click

      click_on 'Preview'
    end

    it 'displays the preview information', bulk_update_step_1: true do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Data Centers')
      expect(page).to have_content('Update Type Find And Update')
      # Find Values to Update
      within '.find-values-preview' do
        expect(page).to have_content('Short Name: ESA/ED')
      end

      # New Values
      within '.new-values-preview' do
        expect(page).to have_content('Short Name: AARHUS-HYDRO')
        expect(page).to have_content('Long Name: Hydrogeophysics Group, Aarhus University ')
        expect(page).to have_no_content('Related Url Content Type:')
        expect(page).to have_no_content('Related Url Type:')
        expect(page).to have_no_content('Related URL:')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@find_and_update_concept_response_2.body['EntryTitle'])
        expect(page).to have_content(@find_and_update_concept_response_2.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before(:each, bulk_update_step_2: true) do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page', bulk_update_step_1: true, bulk_update_step_2: true do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Data Centers')
          expect(page).to have_content('Update Type Find And Update')
        end

        within '.find-values-preview' do
          expect(page).to have_content('Find Values to Update')
          expect(page).to have_content('Short Name: ESA/ED')
        end

        within '.new-values-preview' do
          expect(page).to have_content('New Value')
          expect(page).to have_content('Short Name: AARHUS-HYDRO')
          expect(page).to have_content('Long Name: Hydrogeophysics Group, Aarhus University ')
          expect(page).to have_no_content('Related Url Content Type:')
          expect(page).to have_no_content('Related Url Type:')
          expect(page).to have_no_content('Related URL:')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          visit collection_path(@find_and_update_ingest_response_2['concept-id'])
        end

        it 'displays the updated data center' do
          within '.data-centers-cards' do
            expect(page).to have_no_content('ESA/ED')

            expect(page).to have_content('AARHUS-HYDRO', count: 2)
            expect(page).to have_content('Hydrogeophysics Group, Aarhus University ', count: 2)
          end
        end
      end
    end
  end
end
