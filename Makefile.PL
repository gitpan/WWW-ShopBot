use ExtUtils::MakeMaker;


WriteMakefile
    (
     'NAME'		=> 'WWW::ShopBot',
     'VERSION_FROM'	=> 'ShopBot.pm', 
     'PREREQ_PM'	=> {
	 'File::Find::Rule' => '0.09',
     }, 
     ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'ShopBot.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
