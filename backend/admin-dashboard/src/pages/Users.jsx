import { useState, useEffect } from 'react';
import { getUsers, deleteUser } from '../api';
import { Search, Trash2, Eye, Loader2, ChevronLeft, ChevronRight } from 'lucide-react';

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedUser, setSelectedUser] = useState(null);

  const fetchUsers = (p = 1) => {
    setLoading(true);
    getUsers(p)
      .then((res) => {
        const d = res.data;
        setUsers(d.results || d);
        if (d.count) setTotalPages(Math.ceil(d.count / 20));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchUsers(page); }, [page]);

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this user?')) return;
    try {
      await deleteUser(id);
      setUsers(users.filter((u) => u.id !== id));
    } catch (err) {
      alert('Failed to delete user');
    }
  };

  const filtered = users.filter((u) =>
    (u.full_name || u.username || '').toLowerCase().includes(search.toLowerCase()) ||
    (u.email || '').toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">User Management</h1>
          <p className="text-dashboard-text-muted text-sm mt-1">Manage registered citizens</p>
        </div>
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-dashboard-text-muted" />
          <input
            type="text"
            placeholder="Search users..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-dashboard-card border border-dashboard-border rounded-lg pl-10 pr-4 py-2 text-sm text-white placeholder-dashboard-text-muted focus:outline-none focus:border-nepal-red/50 focus:ring-1 focus:ring-nepal-red/30 transition-all w-64"
          />
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
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Joined Date</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="text-center py-10 text-dashboard-text-muted">
                        No users found.
                      </td>
                    </tr>
                  ) : (
                    filtered.map((user) => (
                      <tr key={user.id} className="transition-colors">
                        <td>
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-nepal-red/30 to-nepal-blue/30 flex items-center justify-center text-white font-semibold text-xs">
                              {(user.full_name || user.username || 'U')[0].toUpperCase()}
                            </div>
                            <span className="text-white font-medium">{user.full_name || user.username}</span>
                          </div>
                        </td>
                        <td className="text-dashboard-text-muted">{user.email}</td>
                        <td className="text-dashboard-text-muted">{user.phone || '—'}</td>
                        <td className="text-dashboard-text-muted">{new Date(user.date_joined).toLocaleDateString()}</td>
                        <td>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            user.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-red-500/20 text-red-400'
                          }`}>
                            {user.is_active ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td>
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => setSelectedUser(user)}
                              className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-nepal-blue hover:bg-nepal-blue/10 transition-all"
                              title="View"
                            >
                              <Eye size={16} />
                            </button>
                            <button
                              onClick={() => handleDelete(user.id)}
                              className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-nepal-red hover:bg-nepal-red/10 transition-all"
                              title="Delete"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between">
            <p className="text-sm text-dashboard-text-muted">
              Page {page} of {totalPages}
            </p>
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

      {/* User Detail Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in" onClick={() => setSelectedUser(null)}>
          <div className="glass rounded-2xl p-6 max-w-md w-full mx-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center gap-4 mb-6">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-nepal-red to-nepal-blue flex items-center justify-center text-white font-bold text-xl">
                {(selectedUser.full_name || selectedUser.username || 'U')[0].toUpperCase()}
              </div>
              <div>
                <h3 className="text-xl font-bold text-white">{selectedUser.full_name || selectedUser.username}</h3>
                <p className="text-dashboard-text-muted text-sm">{selectedUser.email}</p>
              </div>
            </div>
            <div className="space-y-3">
              {[
                ['Phone', selectedUser.phone || '—'],
                ['Username', selectedUser.username],
                ['Joined', new Date(selectedUser.date_joined).toLocaleDateString()],
                ['Status', selectedUser.is_active ? 'Active' : 'Inactive'],
              ].map(([label, val]) => (
                <div key={label} className="flex justify-between py-2 border-b border-dashboard-border last:border-0">
                  <span className="text-dashboard-text-muted text-sm">{label}</span>
                  <span className="text-white text-sm font-medium">{val}</span>
                </div>
              ))}
            </div>
            <button
              onClick={() => setSelectedUser(null)}
              className="w-full mt-6 py-2.5 rounded-lg bg-dashboard-card border border-dashboard-border text-white font-medium hover:bg-dashboard-card-hover transition-all"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
