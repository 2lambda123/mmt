describe 'Displaying the loss report in browser' do
  context 'when accessing the loss report' do

    let(:echo_concept_id) { cmr_client.get_collections({ 'EntryTitle': 'MISR Level 1A Navigation Data V002' }, 'access_token').body.dig('items', 0, 'meta', 'concept-id') }
    let(:dif_concept_id) { cmr_client.get_collections({ 'EntryTitle': 'SeaWiFS Deep Blue Aerosol Optical Depth and Angstrom Exponent Daily Level 3 Data Gridded at 1.0 Degrees V004 (SWDB_L310) at GES DISC' }, 'access_token').body.dig('items', 0, 'meta', 'concept-id') }
    let(:iso_concept_id) { cmr_client.get_collections({ 'EntryTitle': 'SMAP L4 Global 3-hourly 9 km Surface and Rootzone Soil Moisture Analysis Update V002' }, 'access_token').body.dig('items', 0, 'meta', 'concept-id') }

    before do
      login
    end

    context 'when displaying json' do
      it 'properly displays the echo json report' do
        visit loss_report_collections_path(echo_concept_id, format: 'json')
        sample_paths = JSON.parse(File.read('spec/fixtures/loss_report_samples/loss_report_echo_sample.json')).keys.map! { |path| path.split(': ').last }
        sample_values = JSON.parse(File.read('spec/fixtures/loss_report_samples/loss_report_echo_sample.json')).values.map! { |val| val.strip if val.is_a?(String) }
        page_paths = JSON.parse(page.text).keys.map! { |path| path.split(': ').last }
        page_values = JSON.parse(page.text).values.map! { |val| val.strip if val.is_a?(String) }

        expect(sample_paths - page_paths).to be_empty
        expect(page_paths - sample_paths).to be_empty
        expect(sample_values - page_values).to be_empty
        expect(page_values - sample_values).to be_empty
      end

      it 'properly displays the dif json report' do
        visit loss_report_collections_path(dif_concept_id, format: 'json')
        expect(page.text.gsub(/\s+/, "")).to have_text(File.read('spec/fixtures/loss_report_samples/loss_report_dif_sample.json').gsub(/\s+/, ""))
      end

      it 'properly displays the iso json report' do
        visit loss_report_collections_path(iso_concept_id, format: 'json')
        sample_paths = JSON.parse(File.read('spec/fixtures/loss_report_samples/loss_report_iso_sample.json')).keys.map! { |path| path.split(': ').last }
        sample_values = JSON.parse(File.read('spec/fixtures/loss_report_samples/loss_report_iso_sample.json')).values
        page_paths = JSON.parse(page.text).keys.map! { |path| path.split(': ').last }
        page_values = JSON.parse(page.text).values

        # the reason this iso example will have 2 discrepancies (seen in the bottom two 'expect' lines) is because
        # every time an iso collection is translated a few 'id' attributes are generated by CMR and they are always different.
        # This means that the sample reports will contain different 'id' values and therefore cannot be compared directly in this example.
        # In order to bypass this issue we ignore the 'id' changes by expecting two 'id' values that are different, hence the
        # '2' expectation.

        expect(sample_paths - page_paths).to be_empty
        expect(page_paths - sample_paths).to be_empty
        expect((sample_values - page_values).length).to be(2)
        expect((page_values - sample_values).length).to be(2)
      end
    end

    context 'when displaying text' do
      it 'properly displays the echo text report' do
        visit loss_report_collections_path(echo_concept_id, format: 'text')
        sample_paths = File.read('spec/fixtures/loss_report_samples/loss_report_echo_sample.text').split(/\s|\n/).reject! { |path| !path.include?("/") }
        page_paths = page.text.split("\s").reject! { |path| !path.include?("/") }
        expect(sample_paths - page_paths).to be_empty
        expect(page_paths - sample_paths).to be_empty
      end

      it 'properly displays the dif text report' do
        visit loss_report_collections_path(dif_concept_id, format: 'text')
        expect(page.text.gsub(/\s+/, "")).to have_text(File.read('spec/fixtures/loss_report_samples/loss_report_dif_sample.text').gsub(/\s+/, ""))
      end

      it 'properly displays the iso text report' do
        visit loss_report_collections_path(iso_concept_id, format: 'text')

        # the following two lines extract all the paths from the Capybara page and from the sample report.
        # from there, the two arrays of paths are compared to ensure the page does not hold different paths than the sample
        # this is necessary because of how CMR translates ISO records. See above 'json iso report' for more details
        sample_paths = File.read('spec/fixtures/loss_report_samples/loss_report_iso_sample.text').split(/\s|\n/).reject! { |path| !path.include?("/") }
        page_paths = page.text.split("\s").reject! { |path| !path.include?("/") }

        expect(sample_paths - page_paths).to be_empty
        expect(page_paths - sample_paths).to be_empty
      end
    end
  end
end
