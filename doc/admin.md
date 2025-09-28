# PCI ID Administrator's Guide

The web interface to the database lives at https://admin.pci-ids.ucw.cz/.

The public e-mail contact pci-admins@ucw.cz is aliased to all active
administrators.

Nothing is set in stone. There are some rules, but there are situations
that justify bending them. When you are not sure, please consult with the
other administrators at pci-admins@ucw.cz.

If you have ideas how to improve the maintenance process or the web interface,
tell us please.

## Administrative interface

When you log in, you should see an "Administer" link at the top of the page.
It will show a list of all entries, which have been changed and not
confirmed by any moderator yet.

For each vendor/device/subsystem ID, the whole history of submissions and
comments is shown, with the currently active version highlighted in green.
You can use radio buttons next to the entries to choose which entry is active
(by default, the topmost radio button is selected, which means "keep in the
moderators' queue").

Below the submissions, there is a couple of edit boxes. The big one is used
for adding comments. Typically, when somebody submits a suspicious entry,
you should ask for details. The most frequent comments are available under
"Stock answers".

The small edit boxes for Name and Note are used to add a new submission
and make it active automatically. I use them for example when a submission
contains a typo (I just re-submit it with the typo fixed), or when somebody
adds a Note i wish to remove (I copy-and-paste the name of the device to the
edit box and leave the Note edit box empty).

## Typical problems

Here is a list of common mistakes people make, together with the suggested
remedy:

 -  Unjustified deletes or renames. Every attempt to delete an entry
    or to change it to something completely different should contain
    a comment explaining the reason. There is one exception: when the
    modification is made by the author of the previous version.

 -  Typos. Lots of them. For example, people often write "4 port" instead
    of "4-port".

 -  Unnecessary verbosity. Too long entries have to be trimmed, or their
    authors asked to trim the entry.

 -  Repeated vendor names. People (especially salesmen) tend to repeat
    the vendor name at the beginning of the device description. This should
    be never done and there is a stock answer for that. The only exception is
    when a company builds a device marketed under somebody else's brand.

 -  Marketing blurbs. Salespeople tend to submit device descriptions full
    of trademark signs and other rubbish and they can be very determined
    to keep them :) However, they are not our clients, so we are not obliged
    to follow their wishes. Instead, think what will be useful for our users
    -- generally, if some piece of information serves helps nobody identify
    the device, it should not be kept. When you are in doubt, or when the
    salesperson starts speaking in legalese, let me know.

 -  People tend to submit USB devices. Another stock answer.

 -  Excessive notes. Unlike comments, notes are a part of the pci.ids file,
    so they should be used only for important things. Everything else is fine
    to have as a comment.

 -  Renames of vendors. When a company is swallowed by another company,
    they tend to rename the vendor ID in the database. This is allowed, but
    the previous name should be kept as a note (usually, in the form "Nee
    <original name>").

 -  Non-ASCII characters. Although the database supports Unicode, we prefer
    a narrower character set in everything that goes to the pci.ids file.
    Plain ASCII is preferred, accented Latin characters are also OK, but
    we avoid various kinds of Unicode hyphens etc.

 -  Repeated names. Users often add multiple device entries with the same name.
    In such cases, we typically ask for disambiguation.

## Random notes

 -  Some companies keep their traditions, however strange they may seem.
    For example, Intel always submits entries with codenames many months
    before they release a new chip. They update it to the real name later,
    but they wish to keep the codename in Linux distributions, which are
    released in the meantime. Generally, we try to cooperate with them,
    especially when they have a good history of keeping things right.

Now, you should probably try moderating a couple of entries. Feel free to
ask me about anything.
