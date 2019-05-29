# -*- coding: utf-8 -*-

require 'cgi'
require 'json/jsonParser'
require 'fileutils'

require 'dodontof/logger'


module DodontoF
  # ユーティリティメソッドを格納するモジュール
  module Utils
    # オブジェクトを JSON で表現した文字列を返す
    # @param [Object] obj JSON に変換するオブジェクト
    # @return [String]
    def getJsonString(obj)
      JsonBuilder.build(obj)
    end
    module_function :getJsonString

    # JSON 文字列からオブジェクトに変換する
    # @param [String] jsonString JSON 文字列
    # @return [Array, Hash, nil]
    def getObjectFromJsonString(jsonString)
      logger = DodontoF::Logger.instance

      logger.debug(jsonString, 'getObjectFromJsonString start')
      begin
        begin
          # 文字列の変換なしでパースを行ってみる
          parsed = JsonParser.parse(jsonString)
          logger.debug('getObjectFromJsonString parse end')

          return parsed
        rescue => e
          # エスケープされた文字を戻してパースを行う
          parsedWithUnescaping = JsonParser.parse(CGI.unescape(jsonString))
          logger.debug('getObjectFromJsonString parse with unescaping end')

          return parsedWithUnescaping
        end
      rescue => e
        # logger.exception(e)
        return {}
      end
    end
    module_function :getObjectFromJsonString

    # ディレクトリが作成された状態にする
    # この時なければパーミッションが0777の状態で作る
    # またディレクトリではなくファイルが存在したならば
    # そのファイルを削除しながらディレクトリにする
    # (慣例に従ったが、ensureSaveDirとかそういう名前のほうが適切かも)
    def makeDir(dir)
      logger = DodontoF::Logger.instance
      logger.debug(dir, "makeDir dir")

      if( File.exist?(dir) )
        if( File.directory?(dir) )
          return
        end

        File.delete(dir)
      end

      Dir::mkdir(dir)
      File.chmod(0777, dir)
    end
    module_function :makeDir

    # ディレクトリを削除します
    def rmdir(dirName)
      return unless( FileTest.directory?(dirName) )

      # force = true
      # FileUtils.remove_entry_secure(dirName, force)
      # 上記のメソッドは一部レンタルサーバ(さくらインターネット等）で禁止されているので、
      # この下の方法で対応しています。

      logger = DodontoF::Logger.instance

      files = Dir.glob( File.join(dirName, "*") )

      logger.debug(files, "rmdir files")
      files.each do |fileName|
        File.delete(fileName.untaint)
      end

      Dir.delete(dirName)
    end
    module_function :rmdir

    # 指定されたキー値(文字列)に翻訳のための
    # 置換キーであることを示すラッピングを施して返します
    def getLanguageKey(key)
      '###Language:' + key + '###'
    end
    module_function :getLanguageKey

    # 指定の文字列(パスワード)をソルトを用いてエンコードして返す
    # 生の状態でパスワードを保存するのを避けるための措置
    def getChangedPassword(pass)
      return nil if( pass.empty? )

      salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
      return pass.crypt(salt)
    end
    module_function :getChangedPassword

    # 生パスワード(password)と
    # ソルトによりエンコードされたパスワード(changedPassword)が
    # その実態として一致するかチェックします
    # see also: getChangedPassword
    def isPasswordMatch?(password, changedPassword)
      return true if( changedPassword.nil? )
      return false if( password.nil? )
      ( password.crypt(changedPassword) == changedPassword )
    end
    module_function :isPasswordMatch?
  end
end
