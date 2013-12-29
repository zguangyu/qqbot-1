#!/usr/bin/env coffee

int = (v) -> parseInt v
log = console.log
api = require("../src/qqapi")


log "testing..."

config = require '../config'
qq = config.account 
pass = config.password

prompt = (title, callback) ->
    process.stdin.resume()
    process.stdout.write(title)
    process.stdin.on "data",  (data) ->
        data = data.toString().trim()
        # 过滤无效内容
        if data
            callback data 
            process.stdin.pause()
    # control + d to end 
    process.stdin.on 'end', ->
      process.stdout.write('end')
      callback()

test_check_qq = ->
    api.check_qq '123774072' , (result) ->
        log int result[0]
        log result[1]
        log result[2]


test_encode_password = ->
    log api.encode_password(pass,"!PYL",'\\x00\\x00\\x00\\x00\\x07\\x60\\xa4\\x78')
    # should equal to 7BB648B45C561A5F986DECCD94644A3E
    
#  需要验证码的登录
test_encode_password2 = ->
    # verify zkmm
    # '4GJSgm18Bw-8yw5JGKpSOXH-0idqvaCU'
    # \x00\x00\x00\x00\xa5\x13\xed\x18
    log api.encode_password(pass,'zkmm','\\x00\\x00\\x00\\x00\\xa5\\x13\\xed\\x18')
    # should equal to F16B5C4EBE52641313403CB93C0FF569


test_login_full = ->

    login_next = (qq , encoded_pass , verify_code)->
        log "开始登录1 密码校验"
        api.login qq, encoded_pass , verify_code , (ret)->
            log '登录结果'
            log ret
            return unless ret[2].match /^http/
                
            log "开始登录2 cookie获取"
            api.login_step2 ret[2] , (ret) ->                
                log "开始登录3 token 获取"
                api.login_token (ret) ->
                    log ret

    log "验证帐号..."
    api.check_qq qq , (result) ->
        # log "验证帐号:", result
        is_need_verify_code = int result[0]
        verify_code = result[1]
        bits = result[2]        
                
        #TODO:  login_next 异步破坏了代码的结构性，这块如何优化
        if is_need_verify_code
            log "需要验证码...获取中..." 
            api.get_verify_code qq, config.host, config.port, (error) ->
                
                require('child_process').exec 'open tmp'
                log "http://#{config.host}:#{config.port}"
                prompt "输入验证码:" , (code) ->
                    api.finish_verify_code()
                    verify_code  = code
                    log '验证码：' , verify_code
                    new_pass = api.encode_password(pass,verify_code , bits )    
                    login_next( qq , new_pass , verify_code)                        
        else
            new_pass = api.encode_password(pass,verify_code , bits )
            login_next( qq , new_pass , verify_code)    


test_login_token = ->
    api.post (ret) -> log ret


test_get_verify_code = ->
    api.get_verify_code qq, config.host, config.port, (error) ->
        log 'oh yeah'

# test_check_qq()
# test_encode_password2()
test_login_full()
# test_login_token()

# test_get_verify_code()



