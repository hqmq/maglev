#   We currently do not have a BasicSocket class .
#   Ruby BasicSocket and Socket methods are combined into Smalltalk Socket .
#
#   TCPSocket.class open()  does a blocking connect attempt
#   and returns a blocking socket.
#
#   successful TCPServer.accept  returns a new socket whose blocking
#   state is the same as the receiver's
#
#   All other newly created sockets default to non-blocking. Use
#      aSocket.setsockopt('SOL_TCP', 'SO_NONBLOCKING', false)
#   to change a socket to blocking.
#
#   The above is based on the current plan to use blocking sockets
#   for the demo and use methods defined in the existing Ruby socket API.

class Socket

  SOCK_STREAM    = 1
  SOCK_DGRAM     = 2
  SOCK_RAW       = 3
  SOCK_SEQPACKET = 5

  AF_UNSPEC    = 0
  AF_UNIX      = 1
  AF_LOCAL     = AF_UNIX
  AF_INET      = 2
  AF_IMPLINK   = 3
  AF_PUP       = 4
  AF_CHAOS     = 5
  AF_NS        = 6
  AF_ISO       = 7
  AF_OSI       = AF_ISO
  AF_ECMA      = 8
  AF_DATAKIT   = 9
  AF_CCITT     = 10
  AF_SNA       = 11
  AF_DECnet    = 12
  AF_DLI       = 13
  AF_LAT       = 14
  AF_HYLINK    = 15
  AF_APPLETALK = 16
  AF_ROUTE     = 17
  AF_LINK      = 18
  AF_COIP      = 20
  AF_CNT       = 21
  AF_IPX       = 23
  AF_SIP       = 24
  AF_NDRV      = 27
  AF_ISDN      = 28
  AF_E164      = AF_ISDN
  AF_INET6     = 30
  AF_NATM      = 31
  AF_SYSTEM    = 32
  AF_NETBIOS   = 33
  AF_PPP       = 34

  AI_PASSIVE     = 0x00000001
  AI_CANONNAME   = 0x00000002
  AI_NUMERICHOST = 0x00000004
  AI_MASK        = (AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST)
  AI_ALL         = 0x00000100
  AI_ADDRCONFIG  = 0x00000400
  AI_V4MAPPED    = 0x00000800
  AI_DEFAULT     = (AI_V4MAPPED | AI_ADDRCONFIG)

  # accept implemented only in TCPServer .
  # bind, listen not implemented,
  #   use  TCPServer>>new:port:  to create a listening socket

  # send, write, recv  function per the non-blocking state of the receiver.
  primitive_nobridge 'send', 'send:flags:addr:'
  primitive 'send', 'send:flags:'
  primitive_nobridge '<<', 'write:'
  primitive 'write', 'write:'
  primitive 'recv', 'recv:'
  primitive 'read', 'recv:'

  def gets(*args, &blk)
    raise ArgumentError, 'expected 0 or 1 arg'
    #  variants other than gets , gets(terminator) not supported
    # because bridge methods would interfere with use of _storeRubyVcGlobal
  end
  # Smalltalk implementations of   gets  responsible for
  #    _storeRubyVcGlobal  to  store into caller's $_ if any
  primitive_nobridge 'gets', 'gets'
  primitive_nobridge 'gets', 'gets:'

  primitive 'close', 'close'
  primitive_nobridge 'shutdown', 'shutdown'
  primitive 'shutdown', 'shutdown:'
  primitive 'connected?', 'isConnected'

  def eof?
    conn = connected?
    !conn
  end

  # following 2 are in BasicSocket in Ruby 1.8 , but put in Socket for now,
  #  and they only support access to SO_NONBLOCKING , examples:
  #    aSocket.getsockopt('SOL_TCP', 'SO_NONBLOCKING')
  #    aSocket.setsockopt('SOL_TCP', 'SO_NONBLOCKING', aBoolean)
  primitive_nobridge 'setsockopt', 'setsockopt:name:value:'
  primitive 'getsockopt', 'getsockopt:name:'

  class_primitive 'do_not_reverse_lookup', 'setNoReverseLookup:'
# do we have a problem here ?
#  class_primitive 'getaddrinfo', 'getaddrinfo:port:family:type:protocol:flag:'
  class_primitive '_getaddrinfo', 'getaddrinfo:port:'
  class_primitive 'gethostbyname', 'gethostbyname:'
  class_primitive 'gethostname', 'getLocalHostName'
  class_primitive 'new', 'new:type:proto:'

# problem ?
  def self.getaddrinfo(name, port, *args)
    [[2, port, "localhost", "127.0.0.1", nil, nil]]
  end
end

class IPSocket
  class_primitive 'peeraddr', 'peeraddr'
  class_primitive 'getaddress', 'getHostAddressByName:'
end

class TCPSocket

  # open binds a socket to a port and does a blocking connect,
  #  returning a blocking socket.
  class_primitive 'open', 'new:port:'
end

class TCPServer
  # accept returns a new socket, having same non-blocking state as receiver
  primitive 'accept', 'accept'

  # new and open  both create a non-blocking listening socket
  class_primitive 'new', 'new:port:'
  class_primitive 'open', 'new:port:'
end






