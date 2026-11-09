from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.appearance_settings import AppearanceSettings
    from ..models.communication_settings import CommunicationSettings
    from ..models.get_v1_account_response_200_privacy import GetV1AccountResponse200Privacy
    from ..models.workspace_prefs import WorkspacePrefs


T = TypeVar("T", bound="GetV1AccountResponse200")


@_attrs_define
class GetV1AccountResponse200:
    """
    Attributes:
        privacy (GetV1AccountResponse200Privacy | Unset):
        appearance (AppearanceSettings | Unset):
        communication_settings (CommunicationSettings | Unset):
        workspace_prefs (WorkspacePrefs | Unset):
    """

    privacy: GetV1AccountResponse200Privacy | Unset = UNSET
    appearance: AppearanceSettings | Unset = UNSET
    communication_settings: CommunicationSettings | Unset = UNSET
    workspace_prefs: WorkspacePrefs | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        privacy: dict[str, Any] | Unset = UNSET
        if not isinstance(self.privacy, Unset):
            privacy = self.privacy.to_dict()

        appearance: dict[str, Any] | Unset = UNSET
        if not isinstance(self.appearance, Unset):
            appearance = self.appearance.to_dict()

        communication_settings: dict[str, Any] | Unset = UNSET
        if not isinstance(self.communication_settings, Unset):
            communication_settings = self.communication_settings.to_dict()

        workspace_prefs: dict[str, Any] | Unset = UNSET
        if not isinstance(self.workspace_prefs, Unset):
            workspace_prefs = self.workspace_prefs.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if privacy is not UNSET:
            field_dict["privacy"] = privacy
        if appearance is not UNSET:
            field_dict["appearance"] = appearance
        if communication_settings is not UNSET:
            field_dict["communication_settings"] = communication_settings
        if workspace_prefs is not UNSET:
            field_dict["workspace_prefs"] = workspace_prefs

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.appearance_settings import AppearanceSettings
        from ..models.communication_settings import CommunicationSettings
        from ..models.get_v1_account_response_200_privacy import (
            GetV1AccountResponse200Privacy,
        )
        from ..models.workspace_prefs import WorkspacePrefs

        d = dict(src_dict)
        _privacy = d.pop("privacy", UNSET)
        privacy: GetV1AccountResponse200Privacy | Unset
        if isinstance(_privacy, Unset):
            privacy = UNSET
        else:
            privacy = GetV1AccountResponse200Privacy.from_dict(_privacy)

        _appearance = d.pop("appearance", UNSET)
        appearance: AppearanceSettings | Unset
        if isinstance(_appearance, Unset):
            appearance = UNSET
        else:
            appearance = AppearanceSettings.from_dict(_appearance)

        _communication_settings = d.pop("communication_settings", UNSET)
        communication_settings: CommunicationSettings | Unset
        if isinstance(_communication_settings, Unset):
            communication_settings = UNSET
        else:
            communication_settings = CommunicationSettings.from_dict(_communication_settings)

        _workspace_prefs = d.pop("workspace_prefs", UNSET)
        workspace_prefs: WorkspacePrefs | Unset
        if isinstance(_workspace_prefs, Unset):
            workspace_prefs = UNSET
        else:
            workspace_prefs = WorkspacePrefs.from_dict(_workspace_prefs)

        get_v1_account_response_200 = cls(
            privacy=privacy,
            appearance=appearance,
            communication_settings=communication_settings,
            workspace_prefs=workspace_prefs,
        )

        get_v1_account_response_200.additional_properties = d
        return get_v1_account_response_200

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
