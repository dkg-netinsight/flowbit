// Package templates provides NetFlow/IPFIX template system helpers.
package templates

import (
	"github.com/dkg-netinsight/flowbit/v2/decoders/netflow"
)

// TemplateSystemGenerator creates a template system for a source key.
type TemplateSystemGenerator func(key string) netflow.NetFlowTemplateSystem

// DefaultTemplateGenerator creates a basic in-memory template system.
func DefaultTemplateGenerator(key string) netflow.NetFlowTemplateSystem {
	return netflow.CreateTemplateSystem()
}
