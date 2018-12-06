RSpec.describe RegionalOfficesController, type: :controller do
  let!(:user) { User.authenticate! }

  context "index" do
    it "returns all regional offices that hold hearings" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["regional_offices"].size).to eq 57
    end
  end

  context "where a hearing day has an open slot" do
    let!(:child_hearing) do
      create(:case_hearing,
             hearing_type: "V",
             hearing_date: Time.zone.today + 20,
             folder_nr: create(:case).bfkey)
    end

    let!(:co_hearing) do
      create(:case_hearing,
             hearing_type: "C",
             hearing_date: Time.zone.today + 20,
             folder_nr: create(:case).bfkey)
    end

    it "returns hearing dates with open slots" do
      get :open_hearing_dates, params: { regional_office: "C" }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["hearing_dates"].size).to eq 1
    end
  end
end
