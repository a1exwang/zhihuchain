require 'net/http'
require './thread_pool'

$cookies = "z_c0=\"QUFDQUJZa2lBQUFYQUFBQVlRSlZUUmt5ZFZYWkpMd0RPLWRTUVZvNFRPVWU1WklFWjlrRkVnPT0=|1431151897|87429a938888e410fb099c6a61739f52df23ba0d\""
$visited = Array.new

$crawl_threads = ARGV[0].to_i
$name_threads = ARGV[1].to_i
$person = ARGV[2] || 'followers'

def get_followees(location)
  uri = URI(location)
  req = Net::HTTP::Get.new(uri)
  req['Cookie'] = $cookies
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      yield res if block_given?
      ret = []
      followees = res.body.scan /"(http:\/\/www.zhihu.com\/people\/[^ ]*)"/
      followees.each do |f|
        ret.push f.join + "/#{$person}"
        #puts(f.join)
      end
      ret
    else
      res.value
  end
end

def get_user_name(location)
  uri = URI(location)
  req = Net::HTTP::Get.new(uri)
  req['Cookie'] = $cookies
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      all = res.body.scan /<span class="name">([^\/]*)<\/span>/m
      all[1] if all
    else
      nil
  end
end

$pool_names = ThreadPool.new $name_threads
$pool_names.start_task(lambda {
                           |pool, url| puts get_user_name url
                       })

pool_crawl = ThreadPool.new $crawl_threads
pool_crawl.add_resource "http://www.zhihu.com/people/alex-wang-50-59/#{$person}"
pool_crawl.start_task(lambda do |pool, url|
                  unless $visited.include? url
                    $visited.push(url)
                    # 将获取用户名添加到队列
                    $pool_names.add_resource url.gsub("/#{$person}", '')

                    # 将获得followees添加到队列
                    followees = get_followees url
                    followees.each { |f| pool.add_resource(f) }
                  end
                      end)
sleep(20000)
