from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.workspace_prefs_prefs import WorkspacePrefsPrefs


T = TypeVar("T", bound="WorkspacePrefs")


@_attrs_define
class WorkspacePrefs:
    """
    Attributes:
        prefs (WorkspacePrefsPrefs): Empty object when the user has never chosen a workspace (the client falls back to
            their personal one)
    """

    prefs: WorkspacePrefsPrefs
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        prefs = self.prefs.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "prefs": prefs,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.workspace_prefs_prefs import WorkspacePrefsPrefs

        d = dict(src_dict)
        prefs = WorkspacePrefsPrefs.from_dict(d.pop("prefs"))

        workspace_prefs = cls(
            prefs=prefs,
        )

        workspace_prefs.additional_properties = d
        return workspace_prefs

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
