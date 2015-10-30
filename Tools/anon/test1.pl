#
   use strict;
   use Anonymizer;
   use Test::Simple tests=>7; # 2 + 5 * #models

   my @models = (
      'test2.oom'
   );

   ok(&Anonymizer::CheckXMLModel('Anonymizer.pm')==0, 'detect a bad file');
   foreach my $m (@models) {
      ok(&Anonymizer::CheckXMLModel($m)==1, "recognize PD model $m");
   }

   ok(&Anonymizer::LoadXMLModel('xxx') eq '', 'process missing model error');
   foreach my $m (@models) {
      my $read = &Anonymizer::LoadXMLModel($m);
      ok($read ne '' && $read =~ /PowerDesigner/, "load PD model $m");
   
      my $changed = &Anonymizer::ChangeXMLModel($read);
      ok($changed ne '', 'changing model contents');
      ok(length($read) == length($changed), 'preserve model length');
      ok($changed ne $read, 'checking contents changed');
   }

   &Anonymizer::DumpNewAttributes;
