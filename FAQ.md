### I don't want to launch the whole Fabric network but part of it, can I still use these charts?

Yes, you can. Network architecture is defined in `crypto-config.yaml` file, just strip it down to desired components.
But: 
* It's up to you to expose your network components to outer world
* If you are not running an Orderer inside Kubernetes, you cannot use channel and chaincode flows as they are. 
You need to extend the charts to take external Orderer address as a parameter

If you implement these, please feel free to share your extensions :)

### I'm not using `cryptogen` tool but we are creating our own certificates, can I still use these charts?

Yes, you can. As long as you arrange your certificates in a folder structure compatible with `cryptogen` tool.

If you are using intermediary certificates, possibly you need to extend the charts for that.

If you implement this, please feel free to share your extensions :)

### Why is chaincode flow invoking chaincodes? Isn't that creating unnecessary transactions?

Peers create chaincode containers at the very first time chaincode is invoked. This is a time taking operation.
We found it handy to invoke chaincodes for a dummy method immediately to force peers to create chaincode containers.

Anyway, this behaviour can be disabled by passing `flow.invoke.enabled=false` parameter to chaincode flow.

### Can I add new organizations/peers to an already running network?

Hopefully you can :) After creating crypto material, hopefully this will be as easy as making a `helm upgrade..`

We will soon check this scenario and implement necessary changes (if any) as this is a requirement for our project. 

### How can I distinguish between endorser and committer peers when running a network with multiple peers per organization?

We do not distinguish between endorser and committer peers for the sake of simplicity. Each peer is both endorser and committer. 
Technically speaking, the only difference is endorser peers need chaincodes installed to them.

But you can still make your own distinction at application level, as each peer can be accessed separately via its `peer service`

You can also fine tune chaincode flow not to install chaincodes to all peers. (No need to implement anything, 
just invoke chaincode flow with different `crypto-config.yaml` files)

### Why not use Kubernetes native [volume snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) for backup/restore?

Kubernetes volume snapshots do not provide any [consistency guarantees](https://kubernetes.io/blog/2018/10/09/introducing-volume-snapshot-alpha-for-kubernetes/). 
Users are supposed to pause the application or freeze the filesystem etc. before taking the snapshot. So, as Fabric does not provide 
a mechanism for [pausing the peers and orderers](https://jira.hyperledger.org/browse/FAB-15542) for now, we still need to take down 
peers and orderers to take the backup.

For storing backup contents, using an Argo flow seemed more convenient. Volume snapshots are not yet supported by every cloud provider (read AKS) and restoring from a volume snapshot looks like a bit more complicated then our flow.

### Why not use cloud native disk snaphots for backup/restore?

Similar to above, cloud native disk snaphots do not provide any consistency guarantees.

Also, taking snapshot and restoring from it requires lots of cloud specific scripting. Our flow feels much more convenient as it will work on any cloud provider or even locally.
