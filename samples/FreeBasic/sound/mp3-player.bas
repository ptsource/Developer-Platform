'' mp3 player based on FMOD

#include once "fmod.bi"

const SOUND_FILE = "test.mp3"

sub print_all_tags(byval stream as FSOUND_STREAM ptr)
	dim as integer count = 0
	FSOUND_Stream_GetNumTagFields(stream, @count)

	for i as integer = 0 to (count - 1)
		dim as integer tagtype, taglen
		dim as zstring ptr tagname, tagvalue
		FSOUND_Stream_GetTagField(stream, i, @tagtype, @tagname, @tagvalue, @taglen)
		print left(*tagname, taglen)
	next
end sub

function get_tag _
		( _
		byval stream as FSOUND_STREAM ptr, _
		byval tagv1 as zstring ptr, _
		byval tagv2 as zstring ptr _
		) as string

	dim tagname as zstring ptr, taglen as integer

	FSOUND_Stream_FindTagField(stream, FSOUND_TAGFIELD_ID3V1, tagv1, @tagname, @taglen)
	if (taglen = 0) then
		FSOUND_Stream_FindTagField(stream, FSOUND_TAGFIELD_ID3V2, tagv2, @tagname, @taglen)
	end if

	return left(*tagname, taglen)
end function

if (FSOUND_GetVersion < FMOD_VERSION) then
	print "FMOD version " + str(FMOD_VERSION) + " or greater required!"
	end 1
end if

if (FSOUND_Init(44100, 4, 0) = 0) then
	print "Could not initialize FMOD"
	end 1
end if

	FSOUND_Stream_SetBufferSize(50)

	dim as FSOUND_STREAM ptr stream = FSOUND_Stream_Open(SOUND_FILE, FSOUND_MPEGACCURATE, 0, 0)
	if (stream = 0) then
		print "FMOD could not load '" & SOUND_FILE & "'"
		FSOUND_Close()
		end 1
	end if

	'' Read out mp3 tags to show some meta information
	print "Title:", get_tag(stream, "TITLE", "TIT2")
	print "Album:", get_tag(stream, "ALBUM", "TALB")
	print "Artist:", get_tag(stream, "ARTIST", "TPE1")
	''print_all_tags(stream)

	print "Playing mp3, press a key to exit..."
	FSOUND_Stream_Play(FSOUND_FREE, stream)

	while (inkey() = "")
		if (FSOUND_Stream_GetPosition(stream) >= FSOUND_Stream_GetLength(stream)) then
			exit while
		end if
		sleep 50, 1
	wend
   
	FSOUND_Stream_Stop(stream)
	FSOUND_Stream_Close(stream)
	FSOUND_Close()
