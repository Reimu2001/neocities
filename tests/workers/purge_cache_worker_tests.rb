require_relative '../environment.rb'

describe PurgeCacheWorker do
  before do
    @test_ip = '10.0.0.1'
  end

  it 'throws exception without 200 or 404 http status' do
    stub_request(:head, "http://#{@test_ip}/test.jpg").
      with(headers: {'Host' => 'kyledrake.neocities.org', 'Cache-Purge' => '1'})
      .to_return(status: 503)

    worker = PurgeCacheWorker.new

    proc {
      worker.perform @test_ip, 'kyledrake', '/test.jpg'
    }.must_raise RestClient::ServiceUnavailable
  end

  it 'handles 404 without exception' do
    stub_request(:head, "http://#{@test_ip}/test.jpg").
      with(headers: {'Host' => 'kyledrake.neocities.org', 'Cache-Purge' => '1'})
      .to_return(status: 404)

    worker = PurgeCacheWorker.new
    worker.perform @test_ip, 'kyledrake', '/test.jpg'
  end

  it 'sends a purge request' do
    stub_request(:head, "http://#{@test_ip}/test.jpg").
      with(headers: {'Host' => 'kyledrake.neocities.org', 'Cache-Purge' => '1'})
      .to_return(status: 200)

    worker = PurgeCacheWorker.new
    worker.perform @test_ip, 'kyledrake', '/test.jpg'

    assert_requested :head, "http://#{@test_ip}/test.jpg"
  end

  it 'handles spaces correctly' do
    stub_request(:head, "http://#{@test_ip}/te st.jpg").
      with(headers: {'Host' => 'kyledrake.neocities.org', 'Cache-Purge' => '1'})
      .to_return(status: 200)

    url = Addressable::URI.encode_component(
      "http://#{@test_ip}/te st.jpg",
      Addressable::URI::CharacterClasses::QUERY
    )

    worker = PurgeCacheWorker.new
    worker.perform @test_ip, 'kyledrake', '/te st.jpg'

    assert_requested :head, url
  end

  it 'works without forward slash' do
    stub_request(:head, "http://#{@test_ip}/test.jpg").
      with(headers: {'Host' => 'kyledrake.neocities.org', 'Cache-Purge' => '1'})
      .to_return(status: 200)

    worker = PurgeCacheWorker.new
    worker.perform @test_ip, 'kyledrake', 'test.jpg'
  end
end
