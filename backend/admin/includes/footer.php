    <footer class="main-footer">
        <strong>&copy; <?php echo date('Y'); ?> Nestalla.</strong> Panel admin toko buku.
        <div class="float-right d-none d-sm-inline-block">Versi 1.1</div>
    </footer>

</div>

<script src="../assets/adminlte/plugins/jquery/jquery.min.js"></script>
<script src="../assets/adminlte/plugins/bootstrap/js/bootstrap.bundle.min.js"></script>
<script src="../assets/adminlte/dist/js/adminlte.min.js"></script>
<script src="../assets/adminlte/plugins/datatables/jquery.dataTables.min.js"></script>
<script src="../assets/adminlte/plugins/datatables-bs4/js/dataTables.bootstrap4.min.js"></script>

<script>
$(function () {
    // Tabel data berbahasa Indonesia
    $.extend(true, $.fn.dataTable.defaults, {
        language: {
            search: 'Cari:', lengthMenu: 'Tampilkan _MENU_ data',
            info: 'Menampilkan _START_–_END_ dari _TOTAL_ data',
            infoEmpty: 'Tidak ada data', infoFiltered: '(disaring dari _MAX_ data)',
            zeroRecords: 'Tidak ada data yang cocok', emptyTable: 'Belum ada data',
            paginate: { previous: 'Sebelumnya', next: 'Berikutnya' }
        }
    });
    // tabel dengan class .datatable memakai pengaturan umum
    $('.datatable').DataTable({
        paging: true, lengthChange: true, searching: true, ordering: true,
        info: true, autoWidth: false, responsive: true
    });

    // Pesan sukses/gagal hilang sendiri setelah 6 detik
    setTimeout(function () { $('.alert').fadeOut('slow'); }, 6000);

    // Konfirmasi hapus
    $('.btn-delete').on('click', function (e) {
        if (!confirm('Yakin ingin menghapus data ini?')) { e.preventDefault(); }
    });
});
</script>
<?php if (!empty($extra_js)) { echo $extra_js; } ?>
</body>
</html>
