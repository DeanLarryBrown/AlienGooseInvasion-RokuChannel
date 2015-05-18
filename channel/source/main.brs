Sub RunUserInterface()
    o = Setup()
    o.setup()
    o.paint()
    o.eventloop()
End Sub

Sub Setup() As Object
    this = {
		host:	   "76.25.132.254:1337"
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        fonts:     CreateObject("roFontRegistry") 'global font registry
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        setup:     SetupFramedCanvas
        paint:     PaintFramedCanvas
        eventloop: EventLoop
    }

    'Static help text:
    this.help = "Press the right or left arrow buttons on the remote control "
    this.help = this.help + "to seek forward or back through the video at "
    this.help = this.help + "approximately ten second intervals.  Press up  "
    this.help = this.help + "or down to toggle fullscreen."

    'Register available fonts:
    this.fonts.Register("pkg:/fonts/caps.otf")
    this.textcolor = "#406040"

    'Setup image canvas:
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()

    'Resolution-specific settings:
    mode = CreateObject("roDeviceInfo").GetDisplayMode()
    if mode = "720p"
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x: 700, y:   0, w:580, h: 160 }
            left:   { x: 400, y: 500, w: 400, h: 220 }
            right:  { x: 700, y: 177, w: 391, h: 291 }
            bottom: { x: 900, y: 500, w: 300, h: 280 }
			ad:		{ x: 100, y: 500, w: 200, h: 200 }
        }
        this.background = "pkg:/images/back-hd.png"
        this.headerfont = this.fonts.get("lmroman10 caps", 50, 50, false)
    else
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w: 720, h:  80 }
            left:   { x: 100, y: 100, w: 280, h: 210 }
            right:  { x: 400, y: 100, w: 280, h: 210 }
            bottom: { x: 300, y: 340, w: 420, h: 140 }
			ad:		{ x: 100, y: 260, w: 200, h: 200 }
        }
        this.background = "pkg:/images/back-sd.png"
        this.headerfont = this.fonts.get("lmroman10 caps", 30, 50, false)
    end if

    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect(this.layout.right)
	print "http://" this.host "/videos/xplosion.mp4"
    this.player.SetContentList([{
		streamFormat: "mp4"
        Stream: { url: "http://76.25.132.254:1337/videos/xplosion.mp4" }
    }])
    this.player.Play()

    return this
End Sub

Sub EventLoop()
    while true
        msg = wait(0, m.port)
        if msg <> invalid
            'If this is a startup progress status message, record progress
            'and update the UI accordingly:
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                m.paint()

            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                if index = 3 or index = 2'<UP> or <DOWN> (toggle fullscreen)
                    if m.paint = PaintFullscreenCanvas
                        m.setup = SetupFramedCanvas
                        m.paint = PaintFramedCanvas
                        rect = m.layout.right
                    else
                        m.setup = SetupFullscreenCanvas
                        m.paint = PaintFullscreenCanvas
                        rect = { x:0, y:0, w:0, h:0 } 'fullscreen
                        m.player.SetDestinationRect(0, 0, 0, 0) 'fullscreen
                    end if
                    m.setup()
                    m.player.SetDestinationRect(rect)
                else if index = 4 or index = 8  '<LEFT> or <REV>
                    m.position = m.position - 10
                    m.player.Seek(m.position * 1000)
                else if index = 5 or index = 9  '<RIGHT> or <FWD>
                    m.position = m.position + 10
                    m.player.Seek(m.position * 1000)
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
					'TODO add code here to display adds when paused
                end if

            else if msg.isPaused()
                m.paused = true
				'TODO show pause adds
                m.paint()

            else if msg.isResumed()
                m.paused = false
				'TODO hide pause ads
                m.paint()

            end if
            'Output events for debug
			if msg.GetType()=6 
				if msg.GetIndex()>59
					m.position = m.position - 60
					m.player.Seek(m.position * 1000)
					if m.setup = SetupFramedCanvas
						m.setup()
					end if
				end if
			end if
            print msg.GetType(); ","; msg.GetIndex(); ": "; msg.GetMessage()
            if msg.GetInfo() <> invalid print msg.GetInfo();
        end if
    end while
End Sub

Sub SetupFullscreenCanvas()
    m.canvas.AllowUpdates(false)
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFullscreenCanvas()
    list = []

    if m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else if m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else
        color = "#00000000" 'fully transparent
    end if

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
End Sub

Sub SetupFramedCanvas()
    m.canvas.AllowUpdates(false)
    m.canvas.Clear()
    m.canvas.SetLayer(0, [
        { 'Background:
            Url: m.background
            CompositionMode: "Source"
        },
        { 'The title:
            Text: "Alien Goose Invasion"
            TargetRect: m.layout.top
            TextAttrs: { valign: "bottom", font: m.headerfont, color: m.textcolor }
        },
        { 'Help text:
            Text: m.help
            TargetRect: m.layout.left
            TextAttrs: { halign: "left", valign: "top", color: m.textcolor }
        },
		{ 'ad:
            Url: "http://76.25.132.254:1337/nextad.png"
			TargetRect: m.layout.ad
            CompositionMode: "Source"
        }
    ])
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFramedCanvas()
    list = []
    if m.progress < 100  'Video is currently buffering
        list.Push({
            Color: "#80000000"
            TargetRect: m.layout.right
        })
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TargetRect: m.layout.right
        })
    else  'Video is currently playing
        if m.paused
            list.Push({
                Color: "#80000000"
                TargetRect: m.layout.right
                CompositionMode: "Source"
            })
            list.Push({
                Text: "Paused"
                TargetRect: m.layout.right
            })
        else  'not paused
            list.Push({
                Color: "#00000000"
                TargetRect: m.layout.right
                CompositionMode: "Source"
            })
        end if
        list.Push({
            Text: "Current position: " + m.position.tostr() + " seconds"
            TargetRect: m.layout.bottom
            TextAttrs: { halign: "left", valign: "top", color: m.textcolor }
        })
    end if
    m.canvas.SetLayer(1, list)
End Sub
