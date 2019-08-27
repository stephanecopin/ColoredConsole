#!/usr/bin/env perl

use strict;
use Data::Dumper;
use Getopt::Long;

my %codeColors = 
(
    "0x1F3FB" => "#DB2C38",
    "0x1F3FC" => "#41B645",
    "0x1F3FD" => "#C67C48",
    "0x1F3FE" => "#00A0BE",
    "0x1F3FF" => "#B21889",
    "0xF1EED" => "#7F7F7F",
    "0x1F3FF" => "#FFA500",
);

foreach my $fontName ("ColoredConsole-Bold")
{
    my $content = read_file('UTF-8', $fontName.".ttx");
    
    my @glypIds = $content =~ m~<GlyphID name="([^"\.]+)"/>~g;
    
#     die Dumper(\@glypIds);

    my $numPaletteEntries = keys %codeColors;
    
    my $extraGlyphIDs = "";
    my $extraMetrics = "";
    my $extraMaps = "";
    my $extraGlyphs = "";
    my $ligatureSets = "";
    my $colorGlyphs = "";
    my $colors = "";
    
    my $colorIndex = 0;
    foreach my $code (sort keys %codeColors)
    {
        my $intCode = hex($code);
        my $extraGlyphOutlineData = "";
        if ($intCode >= 0x1F3FB && $intCode <= 0x1F3FF)
        {
            $extraGlyphOutlineData = "/><!-- contains no outline data -->"
        }
        else
        {
            $extraGlyphOutlineData = <<'END_EMPTY_INSTRUCTIONS';
 xMin="0" yMin="0" xMax="0" yMax="0">
      <contour/>
      <instructions>
        <assembly>
          CALL[ ]	/* CallFunction */
        </assembly>
      </instructions>
    </TTGlyph>
END_EMPTY_INSTRUCTIONS
        }
        $extraGlyphIDs .= sprintf qq(    <GlyphID name="%s"/>\n), $code;
        $extraMetrics .= sprintf qq(    <mtx name="%s" width="0" lsb="50"/>\n), $code;
        $extraMaps .= sprintf qq(    <map code="%s" name="%s"/>\n), $code, $code;
        $extraGlyphs .= sprintf qq(    <TTGlyph name="%s"%s\n), $code, $extraGlyphOutlineData;
        $colors .= sprintf qq(      <color index="%d" value="%s"/>\n), $colorIndex++, $codeColors{$code};
    }
    
    foreach my $glypId (@glypIds)
    {
        $ligatureSets .= sprintf qq(          <LigatureSet glyph="%s">\n), $glypId;
        my $colorIndex = 0;
        foreach my $code (sort keys %codeColors)
        {
            $extraGlyphIDs .= sprintf qq(    <GlyphID name="%s.%s"/>\n), $glypId, $code;
            $extraMetrics .= sprintf qq(    <mtx name="%s.%s" width="600" lsb="50"/>\n), $glypId, $code;
            $extraGlyphs .= sprintf qq(    <TTGlyph name="%s.%s"/><!-- contains no outline data -->\n), $glypId, $code;
            $ligatureSets .= sprintf qq(            <Ligature components="%s" glyph="%s.%s"/>\n), $code, $glypId, $code;
            $colorGlyphs .= sprintf qq(    <ColorGlyph name="%s.%s"><layer colorID="%d" name="%s"/></ColorGlyph>\n), $glypId, $code, $colorIndex++, $glypId;
        }
        $ligatureSets .= sprintf qq(          </LigatureSet>\n);
    }
    

    
    
    $content =~ s~    <!-- extra GlyphIDs -->\n~$extraGlyphIDs~;
    $content =~ s~    <!-- extra mtxs -->\n~$extraMetrics~;
    $content =~ s~    <!-- extra maps -->\n~$extraMaps~;
    $content =~ s~    <!-- extra TTGlyphs -->\n~$extraGlyphs~;
    $content =~ s~    <!-- LigatureSets -->\n~$ligatureSets~;
    $content =~ s~    <!-- ColorGlyphs -->\n~$colorGlyphs~;
    $content =~ s~      <!-- colors -->\n~$colors~;
    $content =~ s~<numPaletteEntries value="0"/>~<numPaletteEntries value="$numPaletteEntries"/>~;
    
    
    
    
    write_file('UTF-8', $fontName.".colored.ttx", $content);
    
    
    system "ttx", "-o", $fontName.".ttf", $fontName.".colored.ttx";
    
    
    
    
    
}




sub read_file
{
	my ($encoding, $path) = @_;
	open(my($file), '<:encoding('.$encoding.')', $path) || die "error $!: $path\n";
	my $content = "";
	while(<$file>) {
		$content .= $_;
	}
	close $file;
	return $content;
}

sub write_file
{
	my ($encoding, $path, $content) = @_;
	if (defined $content)
	{
		my $parentPath = $path;
		$parentPath =~ s!/?[^/]*$!!;
		
		if (length $parentPath && !-e $parentPath)
		{
			system "mkdir", "-p", $parentPath;
		}
	
		if (!-e $path || read_file($encoding, $path) ne $content)
		{
			open(my($file), '>:encoding('.$encoding.')', $path) || die "error $!: $path\n";
			print $file $content;
			close $file;
		}
	}
	elsif (-e $path)
	{
		system "rm", "-f", $path;
	}
}