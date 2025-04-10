package steam

import (
	"math/rand"
	"time"

	"github.com/paralin/go-steam/netutil"
)

// CMServers contains a list of worldwide servers
var CMServers = []string{
	"146.66.155.38:27017",
	"155.133.248.38:27017",
	"162.254.198.44:27017",
	"162.254.197.39:27017",
	"155.133.226.76:27017",
}

// GetRandomCM returns back a random server anywhere
func GetRandomCM() *netutil.PortAddr {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	servers := CMServers
	addr := netutil.ParsePortAddr(servers[rng.Int31n(int32(len(servers)))])
	if addr == nil {
		panic("invalid address in CMServers slice")
	}
	return addr
} 