import { useState, useEffect } from 'react';
import { getDocuments, deleteDocument } from '../api';
import { Search, Trash2, Loader2, ChevronLeft, ChevronRight, AlertCircle, CheckCircle, Clock } from 'lucide-react';

const statusConfig = {
  valid: { label: 'Valid', color: 'bg-emerald-500/20 text-emerald-400', icon: CheckCircle },
  expiring: { label: 'Expiring', color: 'bg-yellow-500/20 text-yellow-400', icon: Clock },
  expired: { label: 'Expired', color: 'bg-red-500/20 text-red-400', icon: AlertCircle },
};

export default function Documents() {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const fetchDocs = (p = 1) => {
    setLoading(true);
    getDocuments(p)
      .then((res) => {
        const d = res.data;
        setDocuments(d.results || d);
        if (d.count) setTotalPages(Math.ceil(d.count / 20));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchDocs(page); }, [page]);

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this document?')) return;
    try {
      await deleteDocument(id);
      setDocuments(documents.filter((d) => d.id !== id));
    } catch {
      alert('Failed to delete document');
    }
  };

  const filtered = documents.filter((doc) => {
    const matchesSearch =
      (doc.document_type_display || doc.document_type || '').toLowerCase().includes(search.toLowerCase()) ||
      (doc.document_number || '').toLowerCase().includes(search.toLowerCase()) ||
      (doc.user_name || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || (doc.computed_status || doc.status) === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Document Management</h1>
          <p className="text-dashboard-text-muted text-sm mt-1">Track and manage citizen documents</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Status filter */}
          <div className="flex rounded-lg border border-dashboard-border overflow-hidden">
            {['all', 'valid', 'expiring', 'expired'].map((s) => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                  statusFilter === s
                    ? 'bg-nepal-red text-white'
                    : 'text-dashboard-text-muted hover:text-white hover:bg-white/5'
                }`}
              >
                {s}
              </button>
            ))}
          </div>
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-dashboard-text-muted" />
            <input
              type="text"
              placeholder="Search documents..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-dashboard-card border border-dashboard-border rounded-lg pl-10 pr-4 py-2 text-sm text-white placeholder-dashboard-text-muted focus:outline-none focus:border-nepal-red/50 focus:ring-1 focus:ring-nepal-red/30 transition-all w-56"
            />
          </div>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <Loader2 size={40} className="animate-spin text-nepal-red" />
        </div>
      ) : (
        <>
          <div className="glass rounded-xl overflow-hidden animate-fade-in">
            <div className="overflow-x-auto">
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Document Type</th>
                    <th>Document Number</th>
                    <th>Expiry Date</th>
                    <th>Status</th>
                    <th>User</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="text-center py-10 text-dashboard-text-muted">
                        No documents found.
                      </td>
                    </tr>
                  ) : (
                    filtered.map((doc) => {
                      const st = doc.computed_status || doc.status || 'valid';
                      const cfg = statusConfig[st] || statusConfig.valid;
                      const StatusIcon = cfg.icon;
                      return (
                        <tr key={doc.id} className="transition-colors">
                          <td className="text-white font-medium">{doc.document_type_display || doc.document_type}</td>
                          <td className="text-dashboard-text-muted font-mono text-xs">{doc.document_number}</td>
                          <td className="text-dashboard-text-muted">
                            {doc.expiry_date ? new Date(doc.expiry_date).toLocaleDateString() : '—'}
                          </td>
                          <td>
                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${cfg.color}`}>
                              <StatusIcon size={12} />
                              {cfg.label}
                            </span>
                          </td>
                          <td className="text-dashboard-text-muted">{doc.user_name}</td>
                          <td>
                            <button
                              onClick={() => handleDelete(doc.id)}
                              className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-nepal-red hover:bg-nepal-red/10 transition-all"
                              title="Delete"
                            >
                              <Trash2 size={16} />
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between">
            <p className="text-sm text-dashboard-text-muted">Page {page} of {totalPages}</p>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page === 1}
                className="p-2 rounded-lg border border-dashboard-border text-dashboard-text-muted hover:text-white hover:bg-white/5 disabled:opacity-30 transition-all"
              >
                <ChevronLeft size={16} />
              </button>
              <button
                onClick={() => setPage(Math.min(totalPages, page + 1))}
                disabled={page === totalPages}
                className="p-2 rounded-lg border border-dashboard-border text-dashboard-text-muted hover:text-white hover:bg-white/5 disabled:opacity-30 transition-all"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
