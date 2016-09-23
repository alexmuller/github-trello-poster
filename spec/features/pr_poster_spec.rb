require 'github_pull_request'

describe 'Pull Request Poster', :vcr do
  let(:trello_poster) { TrelloPoster.new(ENV['TRELLO_PUBLIC_KEY'], ENV['TRELLO_MEMBER_TOKEN']) }
  subject(:github_pr) { GitHubPullRequest.new(60356369, 1, false, trello_poster) }
  let(:pull_request) { github_pr.login_user.pull_request(60356369, 1) }
  let(:trello_card_id) { pull_request.body.match(/https:\/\/trello.com\/c\/\w{8}/)[0].gsub(/https:\/\/trello.com\/c\//, '') }
  let(:trello_card) { github_pr.trello_poster.client.find(:card, trello_card_id) }

  before(:each) do
    @checklist = trello_card.checklists.first
  end

  after(:each) do
    @checklist.delete_checklist_item(@checklist.check_items.first['id'])
    @checklist.delete
  end

  it 'posts a pull request URL to the Trello card referenced in its commit message' do
    TrelloPoster.new(ENV['TRELLO_PUBLIC_KEY'], ENV['TRELLO_MEMBER_TOKEN'])
    expect(@checklist.check_items.first['name']).to eq(pull_request.html_url)
  end

  context "when a pull request URL is already in a card's checklist" do
    it 'does not post a pull request URL to the Trello card' do
      GitHubPullRequest.new(60356369, 1, false, trello_poster)
      expect(@checklist.check_items.count).to eq(1)
    end
  end

  context "when a pull request has been merged" do
    it "checks the Pull Request off the checklist" do
      GitHubPullRequest.new(60356369, 1, true, trello_poster)
      updated_checklist = trello_card.checklists.first
      expect(updated_checklist.check_items.first['state']).to eq('complete')
    end
  end
end
