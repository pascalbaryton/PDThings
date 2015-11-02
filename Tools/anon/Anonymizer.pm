#
# anonymizer script for PowerDesigner models
# . replace text values with random values to remove confidential information from models
#
# usage:
#    (not yet) perl Anonymizer.pl < entry.xxm > output.xxm
#    perl Anonymizer.pl entry.xxm => gives entry_anon.xxm
#    (not yet) perl Anonymizer.pl x*.xxm foo.xxm => ... wildchar file matching, several arguments
#    perl Anonymizer.pl [-reset] {attribute=[value]} ...
#
   # http://perldoc.perl.org/perlmod.html
   package Anonymizer;

   use strict;
   use Exporter;

   # http://www.perlmonks.org/?node_id=102347
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION     = 0.01;
   @ISA         = qw(Exporter);
   @EXPORT      = ();
   @EXPORT_OK   = qw(CheckXMLModel LoadXMLModel ChangeXMLModel SaveXMLModel DumpNewAttributes);
   %EXPORT_TAGS = ();

   use vars qw($ENC_ASCII $ENC_WESTERNEUROPE $ENC_CHINESE $SUFFIX %ATTRIBUTES %NEWATTS %REPLACED);
   $ENC_ASCII = 'ASC';
   $ENC_WESTERNEUROPE = 'WEU';
   $ENC_CHINESE = 'CHI';
   $SUFFIX = '_anon';
   # 0: don't replace, 1: short string, 2: long string, 3:xxx: constant value
   %ATTRIBUTES = (
       '', 0
      ,'Name', 1
      ,'Code', 1
      ,'Comment', 2
   );
   my $line;
   while (defined($line = <DATA>)) {
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      next if ($line eq '');
      $ATTRIBUTES{$line} = 0;
   }
   %NEWATTS = ();
   %REPLACED = ();

   # from http://www.drdobbs.com/scripts-as-modules/184416165
   __PACKAGE__->run(@ARGV) unless caller();

# -------------------------------------
# as standalone module
sub run
{
   my(@args) = @_;
   print "type: ".ref($args[0])."\n"; ###
   shift(@args); # Local::Modulino as first argument?

   for (my $i=0; $i<=$#args; $i++) {
      my $name = $args[$i];
      if ($name eq '-reset') {
         foreach my $k (keys %Anonymizer::ATTRIBUTES) {
            $Anonymizer::ATTRIBUTES{$k} = 0;
         }
         next;
      }
      if ($name =~ /.=/) {
         # additional attribute
         my($att,$val) = $name =~ /^([^=]+)=(.*)$/;
         if ($att eq '') {
            print "*** unknown attribute parameter '$name'\n";
            next;
         }
         if ($val eq '') {
            $Anonymizer::ATTRIBUTES{$att} = 1;
         }
         else {
            $Anonymizer::ATTRIBUTES{$att} = '3:'.$val;
         }
         next;
      }
      if ($name eq '') {
         print STDERR "Usage: perl Anonymizer.pl file_name\n";
         exit(0);
      }
      if (!&CheckXMLModel($name)) {
         print STDERR "*** '$name' not an XML PowerDesigner model\n";
         exit(1);
      }
      my $in = &LoadXMLModel($name);
      if ($in eq '') {
         print STDERR "*** unable to read '$name'\n";
         exit(1);
      }
      my $out = &ChangeXMLModel($in);
      if (defined($out) && $out ne '1') {
         my($f,$x) = $name =~ /^(.*)\.([^\.]+)$/;
         if ($x eq '') {
            $f = $name;
         }
         else {
            $x = '.' . $x;
         }
         my $outn = $f.$SUFFIX.$x;
         if (-f $outn) {
            print STDERR "*** output '$outn' already exists\n";
            exit(1);
         }
         if (&SaveXMLModel($outn, $out)) {
            print STDERR "*** unable to write '$outn'\n";
            exit(1);
         }
         print STDERR "... output '$outn'\n";
      }
   }

   exit(0);
}

# -------------------------------------
# check whether a file might be a PowerDesigner XML model
# return 1 if correct file
sub CheckXMLModel
{
   my($filename) = @_;
   return 0 if (!-f $filename || !open(READ, "<$filename"));
   my $ret = 1;
   my $line;
   if ($ret) {
      $line = <READ>;
      $ret = 0 if ($line !~ /^<\?xml version="1.0" encoding="UTF-8"\?>/);
   }
   if ($ret) {
      $line = <READ>;
      $ret = 0 if ($line !~ /^<\?PowerDesigner /);
   }
   close(READ);
   return $ret;
}

# -------------------------------------
# load file contents
sub LoadXMLModel
{
   my($filename) = @_;
   return '' if ($filename eq '' || !-f $filename || !open(READ, '<:encoding(UTF-8)', $filename));
   my $in;
   my $line;
   while (defined($line = <READ>)) {
      $in .= $line;
   }
   close(READ);
   return $in;
}

# -------------------------------------
# return 1 in case of error
sub SaveXMLModel
{
   my($filename, $str) = @_;
   if (!open(WRITE, '>:utf8', $filename)) {
      return 1;
   }
   print WRITE $str;
   close(WRITE);
   return 0;
}

# -------------------------------------
# takes the model contents in input
# returns 1 in case of error, undef if nothing changed, else the updated model contents
sub ChangeXMLModel
{
   my($stream) = @_;
   my $ret;
   while ($stream ne '') {
      my $start;
      my $repl;
      if (substr($stream,0,1) eq '<') {
         ($start) = $stream =~ /^(<[^>]+>)/;
         $repl = $start;
         if ($start eq '') {
            print STDERR "*** un-closed '<' in stream\n";
            return 1;
         }
         if (substr($start,0,3) eq '<a:' && $start !~ /\/>/) {
            my($attname) = $start =~ /^<a:([a-zA-Z0-9\.]+)/;
            if ($attname eq '') {
               print STDERR "*** un-matched attribute name in '$start'\n";
            }
            if (!exists($Anonymizer::ATTRIBUTES{$attname})) {
               $Anonymizer::NEWATTS{$attname}++;
            }
            elsif ($Anonymizer::ATTRIBUTES{$attname} == 0) {
               # don't replace
               my($value,$ending) = substr($stream, length($start)) =~ /^([^>]*)(<\/a:${attname}>)/;
               if ($ending eq '') {
                  print STDERR "*** unable to find attribute $attname ending\n";
                  return 1;
               }
               else {
                  $start .= $value.$ending;
                  $repl = $start;
               }
            }
            elsif ($Anonymizer::ATTRIBUTES{$attname} == 1 || $Anonymizer::ATTRIBUTES{$attname} == 2) {
               my($value,$ending) = substr($stream, length($start)) =~ /^([^>]*)(<\/a:${attname}>)/;
               if ($ending eq '') {
                  print STDERR "*** unable to find attribute $attname ending\n";
                  return 1;
               }
               else {
                  $start .= $value.$ending;
                  my $replace;
                  if (exists($REPLACED{$value})) {
                     $replace = $REPLACED{$value};
                  }
                  else {
                     $replace = &ReplaceString($value);
                     $REPLACED{$value} = $replace;
                  }
                  $repl .= $replace.$ending;
               }
            }
            elsif (substr($Anonymizer::ATTRIBUTES{$attname},0,2) eq '3:') {
               my $replace = substr($Anonymizer::ATTRIBUTES{$attname},2);
               my($value,$ending) = substr($stream, length($start)) =~ /^([^>]*)(<\/a:${attname}>)/;
               if ($ending eq '') {
                  print STDERR "*** unable to find attribute $attname ending\n";
                  return 1;
               }
               else {
                  $start .= $value.$ending;
                  $repl .= $replace.$ending;
               }
            }
         }
      }
      else {
         ($start) = $stream =~ /^([^<]+)/s;
         $start = $stream if ($start eq '');
         $repl = $start;
      }
      $ret .= $repl;
      $stream = substr($stream, length($start));
   }
   return $ret;
}

# -------------------------------------
sub DumpNewAttributes
{
   my $first = 1;
   foreach my $k (sort keys %Anonymizer::NEWATTS) {
      if ($first) {
         print STDERR "... new attributes:\n";
         $first = 0;
      }
      print STDERR "   $k\n";
   }
}

# -------------------------------------
# detect the charsets of the input string
# e.g. ASC or ASC,CHI
sub DetectCharset
{
   my($str) = @_;
   # TODO detect charsets
   return $ENC_ASCII;
}

# -------------------------------------
# random generation of a replacement
sub ReplaceString
{
   my($str) = @_;
   return '' if ($str eq '');
   my $charsets = &DetectCharset($str);
   # TODO use charsets for generation
   my $ret;
   for (my $i=0; $i<length($str); $i++) {
      my $c = 32+int(rand(96));
      $ret .= chr($c);
   }
   return $ret;
}

# -------------------------------------
# please the "use"
1;

__DATA__

AutoAdjustToText
BackgroundPictureID
BrushStyle
CheckGlobalScript
Classifier.Abstract
ColFilter
ColumnFilters
Content
CornerStyle
CreationDate
Creator
CriterionInfo
CustomPictureID
CustomPictureType
CustomPictureUpdateText
CustomTextMode
DefaultSize
DisplayPreferences
ExtendedAttributeTargetItem.DataType
ExtendedAttributesText
ExtendedBaseCollection.CollectionName
ExtendedMetaModelSignature
ExtractionBranchID
ExtractionDate
ExtractionID
ExtractionVersion
FillColor
FontList
FormTargetItem.Value
FormType
GradientEndColor
GradientFillMode
History
IconMode
IncludeShortcuts
IncludeSubPackages
KeepAspect
Label
LibraryID
LineColor
LineWidth
List
ListedClassKind
ManagerID
ManuallyResized
MapTargetItem.Value
MenuCommandName
ModelOptionsText
ModificationDate
Modifier
ObjectID
Operation.Abstract
OriginalClassID
OriginalID
OriginalUOL
PackageOptionsText
PageMargins
PageOrientation
PaperSize
PaperSource
Path
PersistentSelection.ObjectSelection
PictureFillMode
PictureID
PictureType
PluralLabel
Rect
RepositoryFilename
RepositoryID
RepositoryInformation
ReturnType
RowFilter
SelectionFolderIdentifier
SelectionModes
ShadowColor
ShowAsCircle
SourceObjectPublicName
Stereotype
SubSymbolsLayout
SymbolContent
TargetCategory.Type
TargetClassID
TargetID
TargetLibraryID
TargetModelClassID
TargetModelID
TargetModelLastModificationDate
TargetModelURL
TargetObjectPublicName
ToolIcon
TypePublicName
UseParentNamespace
