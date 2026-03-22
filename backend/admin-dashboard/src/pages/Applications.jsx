import { useState, useEffect } from 'react';
import { getApplications, updateApplicationStatus } from '../api';
import { Search, Loader2, ChevronLeft, ChevronRight, CheckCircle, XCircle, Clock, Hourglass } from 'lucide-react';

const statusConfig = {
  pending: { label: 'Pending', color: 'bg-yellow-500/20 text-yellow-400', icon: Clock },
  processing: { label: 'Processing', color: 'bg-blue-500/20 text-blue-400', icon: Hourglass },
  approved: { label: 'Approved', color: 'bg-emerald-500/20 text-emerald-400', icon: CheckCircle },
  rejected: { label: 'Rejected', color: 'bg-red-500/20 text-red-400', icon: XCircle },
};

export default function Applications() {
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [updating, setUpdating] = useState(null);

  const fetchApps = (p = 1) => {
    setLoading(true);
    getApplications(p)
      .then((res) => {
        const d = res.data;
        setApplications(d.results || d);
        if (d.count) setTotalPages(Math.ceil(d.count / 20));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchApps(page); }, [page]);

  const handleStatusUpdate = async (id, newStatus) => {
    setUpdating(id);
    try {
      const res = await updateApplicationStatus(id, newStatus);
      setApplications(applications.map((a) => (a.id === id ? res.data : a)));
    } catch {
      alert('Failed to update status');
    } finally {
      setUpdating(null);
    }
  };

  const filtered = applications.filter((app) => {
    const matchesSearch =
      (app.service_name || '').toLowerCase().includes(search.toLowerCase()) ||
      (app.user_name || '').toLowerCase().includes(search.toLowerCase()) ||
      (app.reference_number || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || app.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Applications</h1>
          <p className="text-dashboard-text-muted text-sm mt-1">Manage service applications</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex rounded-lg border border-dashboard-border overflow-hidden">
            {['all', 'pending', 'processing', 'approved', 'rejected'].map((s) => (
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
              placeholder="Search applications..."
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
                    <th>Reference</th>
                    <th>Service Type</th>
                    <th>User</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="text-center py-10 text-dashboard-text-muted">
                        No applications found.
                      </td>
                    </tr>
                  ) : (
                    filtered.map((app) => {
                      const cfg = statusConfig[app.status] || statusConfig.pending;
                      const StatusIcon = cfg.icon;
                      return (
                        <tr key={app.id} className="transition-colors">
                          <td className="text-white font-mono text-xs font-medium">{app.reference_number}</td>
                          <td className="text-white">{app.service_name}</td>
                          <td className="text-dashboard-text-muted">{app.user_name}</td>
                          <td>
                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${cfg.color}`}>
                              <StatusIcon size={12} />
                              {cfg.label}
                            </span>
                          </td>
                          <td className="text-dashboard-text-muted">
                            {new Date(app.submitted_at).toLocaleDateString()}
                          </td>
                          <td>
                            {updating === app.id ? (
                              <Loader2 size={16} className="animate-spin text-nepal-red" />
                            ) : (
                              <div className="flex items-center gap-1">
                                {app.status !== 'approved' && (
                                  <button
                                    onClick={() => handleStatusUpdate(app.id, 'approved')}
                                    className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-emerald-400 hover:bg-emerald-500/10 transition-all"
                                    title="Approve"
                                  >
                                    <CheckCircle size={16} />
                                  </button>
                                )}
                                {app.status !== 'rejected' && (
                                  <button
                                    onClick={() => handleStatusUpdate(app.id, 'rejected')}
                                    className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-nepal-red hover:bg-nepal-red/10 transition-all"
                                    title="Reject"
                                  >
                                    <XCircle size={16} />
                                  </button>
                                )}
                              </div>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>

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
