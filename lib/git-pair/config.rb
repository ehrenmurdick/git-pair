module GitPair
  module Config
    extend self

    def all_author_strings
      `git config --global --get-all git-pair.authors`.split("\n")
    end

    def avatar(authors)
      require 'digest/md5'
      require 'rmagick'
      require 'open-uri'

      imgs = []

      authors.each do |auth|
        hash = Digest::MD5.hexdigest(auth.email)
        image_src = "http://www.gravatar.com/avatar/#{hash}"

        imgs << Magick::Image.from_blob(open(image_src).read).first
      end

      imgs.first.crop!(0, 0, imgs.first.columns / 2, imgs.first.rows)

      midline = Magick::Image.new(2, imgs.last.columns, Magick::HatchFill.new('#800','#800'))

      imgs.last.composite!(imgs.first, Magick::WestGravity, Magick::AtopCompositeOp)
      imgs.last.composite!(midline, Magick::CenterGravity, Magick::AtopCompositeOp)


      filename = authors.map { |a| initials(a.name) }.join("+")

      imgs.last.write("#{filename}.jpg")
    end

    def add_author(author)
      unless Author.exists?(author)
        `git config --global --add git-pair.authors "#{author.name} <#{author.email}>"`
      end
    end

    def remove_author(name)
      `git config --global --unset-all git-pair.authors "^#{name} <"`
      `git config --global --remove-section git-pair` if all_author_strings.empty?
    end

    def switch(authors)
      authors.sort!

      `git config user.name "#{authors.map { |a| a.name }.join(' + ')}"`
      `git config user.email "#{Author.email(authors)}"`
    end

    def reset
      `git config --remove-section user`
    end

    def default_email
      `git config --global --get user.email`.strip
    end

    def current_author
      `git config --get user.name`.strip
    end

    def current_email
      `git config --get user.email`.strip
    end

    def initials(name)
      name.split.map { |word| word[0].chr }.join.downcase
    end

    def current_initials
      current_author.split('+').map do |auth|
        initials(auth)
      end.join('+')
    end

  end
end
