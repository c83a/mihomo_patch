sed -i 's/func (gb \*GroupBase) GetProxies(touch bool) \[\]C.Proxy {/func (gb *GroupBase) _GetProxies(touch bool) []C.Proxy {/' adapter/outboundgroup/groupbase.go



sed -i '/func (gb \*GroupBase) _GetProxies(touch bool) \[\]C.Proxy {/i\
\
func (gb *GroupBase) GetProxies(touch bool) (proxies []C.Proxy) {\
\tproxies = gb.providerProxies\
\tif proxies != nil {\
\t\treturn\
\t}\
\tgb.failedTestMux.Lock()\
\tdefer gb.failedTestMux.Unlock()\
\tproxies = gb.providerProxies\
\tif proxies != nil {\
\t\treturn\
\t}\
\tchDirtyCache := make(chan struct{}, 1)\
\tchDone := tunnel.World\
\ttf := false\
\ttype follow interface {\
\t\tAddFollower(chan<- struct{})\
\t}\
\tfor _, pd := range gb.providers {\
\t\tif pf, ok := pd.(follow); ok {\
\t\t\tpf.AddFollower(chDirtyCache)\
\t\t\ttf = true\
\t\t}\
\t}\
\tproxies = gb._GetProxies(false)\
\tgb.providerProxies = proxies\
\tupdater := func() {\
\t\tfor {\
\t\t\tselect {\
\t\t\tcase <-chDirtyCache:\
\t\t\t\tgb.providerProxies = gb._GetProxies(false)\
\t\t\tcase <-chDone:\
\t\t\t\treturn\
\t\t\t}\
\t\t}\
\t}\
\tif tf {\
\t\ngo updater()\
\t}\
\treturn\
}' adapter/outboundgroup/groupbase.go
echo  adapter/outboundgroup/groupbase.go
sed -i '/	"time"/a\	"sync/atomic"'  adapter/outboundgroup/loadbalance.go
sed -i '/case "consistent-hashing":/i\
\ncase "round-robin0":\
\tstrategyFn = strategyRoundRobin0(option.URL)' adapter/outboundgroup/loadbalance.go
echo adapter/outboundgroup/loadbalance.go

sed -i '/func strategyConsistentHashing(url string) strategyFn {/i\
\
func strategyRoundRobin0(url string) strategyFn {\
\tidx := &atomic.Uint32{}\
\treturn func(proxies []C.Proxy, metadata *C.Metadata, touch bool) (proxy C.Proxy) {\
\t\tproxy = proxies[idx.Add(1) % (uint32)(len(proxies))]\
\t\treturn proxy\
\t}\
}' adapter/outboundgroup/loadbalance.go
echo adapter/outboundgroup/loadbalance.go

sed -i '/	"time"/a\	"sync"'  adapter/provider/provider.go
sed -i '/type proxySetProvider struct {/a\
\tmutex    sync.Mutex\
\tfollower map[chan <- struct{}]struct{}' adapter/provider/provider.go
echo adapter/provider/provider.go

sed -i '/func (pp \*proxySetProvider) MarshalJSON() (\[\]byte, error) {/i\
\
func (pp *proxySetProvider) AddFollower(c chan<- struct{})  {\
\tpp.mutex.Lock()\
\tdefer pp.mutex.Unlock()\
\tif len(pp.follower) == 0 {\
\t\tpp.follower = make(map[chan <- struct{}]struct{})\
\t}\
\tpp.follower[c] = struct{}{}\
}\
func (pp *proxySetProvider) UpdateFollower()  {\
\tpp.mutex.Lock()\
\tdefer pp.mutex.Unlock()\
\tfor c := range pp.follower {\
\t\tselect {\
\t\t\tcase c <- struct{}{}:\
\t\t\t\t// pass\
\t\t\tdefault:\
\t\t\t\t// pass\
\t\t\t}\
\t}\
}\
func (pp *proxySetProvider) setProxies(proxies []C.Proxy) {\
\	pp.baseProvider.setProxies(proxies)\
\	pp.UpdateFollower()\
\}' adapter/provider/provider.go
echo adapter/provider/provider.go
sed -i  '/func OnSuspend() {/{
i var World = make(chan struct{})

a \	close(World)\
\	World = make(chan struct{})

}
' tunnel/tunnel.go
echo tunnel/tunnel.go

